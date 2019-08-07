//
//  MAPUploadManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUploadManager.h"
#import <AWSS3/AWSS3.h>
#import "MAPSequence.h"
#import "MAPSequence+Private.h"
#import "MAPImage+Private.h"
#import "MAPFileManager.h"
#import "MAPExifTools.h"
#import "MAPDefines.h"
#import "MAPImage+Private.h"
#import <objc/runtime.h>
#import "MAPUploadManager+Private.h"
#import "MAPDataManager.h"

#define FOREGROUND 1
#define BACKGROUND 2
#define UPLOAD_MODE FOREGROUND

@interface MAPUploadManager()

@property (nonatomic) NSMutableArray* sequencesToUpload;
@property (nonatomic) NSMutableArray* imagesToUpload;
@property (nonatomic) MAPUploadManagerStatus* status;

@property (nonatomic) NSURLSession* uploadSession;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundUpdateTask;

@property (nonatomic) NSDate* dateLastUpdate;
@property (nonatomic) NSMutableArray* speedArray;
@property (nonatomic) NSTimer* speedTimer;
@property (nonatomic) int64_t bytesUploadedSinceLastUpdate;

@end

@implementation MAPUploadManager

+ (instancetype)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.sequencesToUpload = [NSMutableArray array];
        self.imagesToUpload = [NSMutableArray array];
        self.status = [[MAPUploadManagerStatus alloc] init];
        self.dateLastUpdate = [NSDate date];
        self.speedArray = [NSMutableArray arrayWithCapacity:5];
        self.allowsCellularAccess = YES;
        self.testUpload = NO;
        self.deleteAfterUpload = YES;
        self.bytesUploadedSinceLastUpdate = 0;
        self.numberOfSimultaneousUploads = 4;
        
        [self setupAws];
        [self createSession];
        [self loadState];
    }
    
    return self;
}

- (void)processSequences:(NSArray*)sequences forceReprocessing:(BOOL)forceReprocessing
{
    if (self.status.processing || self.status.uploading)
    {
        return;
    }
    
    self.status.uploading = NO;
    self.status.processing = YES;
    self.status.imageCount = 0;
    self.status.imagesUploaded = 0;
    self.status.imagesFailed = 0;
    self.status.imagesProcessed = 0;
    self.status.uploadSpeedBytesPerSecond = 0;
    
    [self.imagesToUpload removeAllObjects];
    [self.sequencesToUpload removeAllObjects];
    
    [self.sequencesToUpload addObjectsFromArray:sequences];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (MAPSequence* sequence in self.sequencesToUpload)
        {
            NSArray* images = [sequence getImages];
            
            for (MAPImage* image in images)
            {
                [self createBookkeepingForImage:image];
            }
            
            self.status.imageCount += images.count;
            
            [sequence lock];
        }
        
        [self startProcessing:forceReprocessing];
        
    });
}

- (void)processAndUploadSequences:(NSArray*)sequences forceReprocessing:(BOOL)forceReprocessing
{
    [self processAndUploadSequences:sequences forceProcessing:forceReprocessing];
}

- (void)uploadSequences:(NSArray*)sequences
{
    [self processAndUploadSequences:sequences forceProcessing:NO];
}

- (void)stopProcessing
{
    self.status.processing = NO;
    
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        [sequence unlock];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(processingStopped:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate processingStopped:self status:self.status];
        });
    }
}

- (void)stopUpload
{
    self.status.processing = NO;
    self.status.uploading = NO;
    
    [self.speedTimer invalidate];
    self.speedTimer = nil;
    
    [self.uploadSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
        
        for (NSURLSessionTask* task in tasks)
        {
            [task cancel];
        }
        
        [self.uploadSession invalidateAndCancel];
        self.uploadSession = nil;
        
        for (MAPSequence* sequence in self.sequencesToUpload)
        {
            [sequence unlock];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStopped:status:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadStopped:self status:self.status];
            });
        }
        
    }];        
}

- (MAPUploadManagerStatus*)getStatus
{
    return self.status;
}

- (NSURLSession*)getSession
{
    return self.uploadSession;
}

#pragma mark - internal

- (void)loadState
{
    if (UPLOAD_MODE == FOREGROUND)
    {
        self.status.uploading = NO;
        self.status.imageCount = 0;
        self.status.imagesProcessed = 0;
        self.status.imagesUploaded = 0;
        self.status.imagesFailed = 0;
    }
    else
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [self.uploadSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            
            self.status.uploading = NO;
            self.status.imageCount = 0;
            self.status.imagesProcessed = 0;
            self.status.imagesUploaded = 0;
            self.status.imagesFailed = 0;
            
            for (NSURLSessionTask* task in uploadTasks)
            {
                if (task.state == NSURLSessionTaskStateRunning)
                {
                    self.status.uploading = YES;
                    [task suspend];
                }
            }
            
            NSArray* sequences = [MAPFileManager getSequences:YES];
            
            if (self.status.uploading)
            {
                for (MAPSequence* sequence in sequences)
                {
                    if ([sequence isLocked])
                    {
                        [self.sequencesToUpload addObject:sequence];
                        
                        NSArray* dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sequence.path error:nil];
                        
                        NSArray* scheduled = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.scheduled'"]];
                        NSArray* processed = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.processed'"]];
                        NSArray* done = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.done'"]];
                        NSArray* failed = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.failed'"]];
                        
                        self.status.uploading = YES;
                        self.status.imageCount += scheduled.count;
                        self.status.imagesProcessed += processed.count;
                        self.status.imagesUploaded += done.count;
                        self.status.imagesFailed += failed.count;
                        self.dateLastUpdate = [NSDate date];
                        
                        for (NSURLSessionTask* task in uploadTasks)
                        {
                            if (task.state == NSURLSessionTaskStateSuspended)
                            {
                                [task resume];
                            }
                        }
                    }
                }
            }
            else
            {
                [self cleanUp];
            }
            
            dispatch_semaphore_signal(semaphore);
            
        }];
        
        // Wait here intil done
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)setupAws
{
    AWSRegionType region = AWSRegionEUWest1;
    AWSCognitoCredentialsProvider* credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:region identityPoolId:AWS_COGNITO_IDENTITY_POOL_ID];
    AWSServiceConfiguration* configuration = [[AWSServiceConfiguration alloc] initWithRegion:region credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

- (void)startUpload:(BOOL)forceProcessing
{
    NSDictionary* processedImages = [[MAPDataManager sharedManager] getProcessedImages];
    
    self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        [self calculateUploadSpeed];
        
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        int taskCount = 0;
        
        for (MAPSequence* sequence in self.sequencesToUpload)
        {
            for (MAPImage* image in [sequence getImages])
            {
                if (!self.status.uploading)
                {
                    return;
                }
                
                [self processImage:image sequence:sequence processedImages:processedImages forceProcessing:forceProcessing];
                
                // For background uploading, schedule all tasks
                if (UPLOAD_MODE == BACKGROUND)
                {
                    [self createTask:image];
                }
                // For foreground uploading, schedule only a few tasks now
                else
                {
                    if (taskCount < self.numberOfSimultaneousUploads)
                    {
                        [self createTask:image];
                        taskCount++;
                    }
                    else
                    {
                        [self.imagesToUpload addObject:image];
                    }
                }
            }
        }
    });
}

- (void)startProcessing:(BOOL)forceReprocessing
{
    NSDictionary* processedImages = [[MAPDataManager sharedManager] getProcessedImages];
    
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        for (MAPImage* image in [sequence getImages])
        {
            if (!self.status.processing)
            {
                return;
            }
            
            if (forceReprocessing || (processedImages[image.imagePath.lastPathComponent] == nil && ![MAPExifTools imageHasMapillaryTags:image]))
            {
                BOOL success = [MAPExifTools addExifTagsToImage:image fromSequence:sequence];
                if (success)
                {
                    [[MAPDataManager sharedManager] setImageAsProcessed:image];
                }
            }
            
            self.status.imagesProcessed++;
            [self setBookkeepingProcessedForImage:image];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(imageProcessed:image:status:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate imageProcessed:self image:image status:self.status];
                });
            }
        }
    }
    
    self.status.processing = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(processingFinished:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate processingFinished:self status:self.status];
        });
    }
}

- (void)processAndUploadSequences:(NSArray*)sequences forceProcessing:(BOOL)forceProcessing
{
    if (self.status.processing || self.status.uploading)
    {
        return;
    }
    
    if (self.uploadSession == nil || self.uploadSession.configuration.allowsCellularAccess != self.allowsCellularAccess || self.uploadSession.configuration.HTTPMaximumConnectionsPerHost != self.numberOfSimultaneousUploads)
    {
        [self createSession];
    }
    
    self.status.uploading = YES;
    self.status.processing = NO;
    self.status.imageCount = 0;
    self.status.imagesUploaded = 0;
    self.status.imagesFailed = 0;
    self.status.imagesProcessed = 0;
    self.status.uploadSpeedBytesPerSecond = 0;
    self.dateLastUpdate = [NSDate date];
    self.bytesUploadedSinceLastUpdate = 0;
    
    [self.speedArray removeAllObjects];
    
    [self.sequencesToUpload removeAllObjects];
    [self.sequencesToUpload addObjectsFromArray:sequences];
    
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        NSArray* images = [sequence getImages];
        self.status.imageCount += images.count;
        
        for (MAPImage* image in images)
        {
            [self createBookkeepingForImage:image];
        }
        
        [sequence lock];
    }
    
    [self startUpload:forceProcessing];
}

- (void)createSession
{
    if (self.uploadSession)
    {
        [self.uploadSession invalidateAndCancel];
        self.uploadSession = nil;
    }
    
    NSURLSessionConfiguration* configuration = nil;
    
    if (UPLOAD_MODE == FOREGROUND)
    {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    else
    {
        configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.mapillary.sdk.networking.upload"];
    }
    
    configuration.HTTPMaximumConnectionsPerHost = self.numberOfSimultaneousUploads;
    
    self.uploadSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
}

- (void)processImage:(MAPImage*)image sequence:(MAPSequence*)sequence processedImages:(NSDictionary*)processedImages forceProcessing:(BOOL)forceProcessing
{
    if (forceProcessing || (processedImages[image.imagePath.lastPathComponent] == nil && ![MAPExifTools imageHasMapillaryTags:image]))
    {
        BOOL success = [MAPExifTools addExifTagsToImage:image fromSequence:sequence];
        if (success)
        {
            [[MAPDataManager sharedManager] setImageAsProcessed:image];
        }
    }
    
    self.status.imagesProcessed++;
    [self setBookkeepingProcessedForImage:image];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageProcessed:image:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate imageProcessed:self image:image status:self.status];
        });
    }
    
    if (self.status.imagesProcessed == self.status.imageCount && self.delegate && [self.delegate respondsToSelector:@selector(processingFinished:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate processingFinished:self status:self.status];
        });
    }
}

- (NSURLSessionUploadTask*)createTask:(MAPImage*)image
{
    // Create task and schedule for upload
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSURLSessionUploadTask* uploadTask = nil;
    
    [self createRequestForImage:image request:^(NSURLRequest *request) {
        
        uploadTask = [self.uploadSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:image.imagePath]];
        
        [uploadTask setTaskDescription:image.imagePath];
        [uploadTask resume];
        
        dispatch_semaphore_signal(semaphore);

    }];
    
    // Wait here intil done
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return uploadTask;
}

- (void)createRequestForImage:(MAPImage*)image request:(void (^) (NSURLRequest* request))result
{
    NSString* bucket = nil;
    
    if (self.testUpload)
    {
        bucket = @"test.balda.public.bucket";
    }
    else
    {
        bucket = @"mapillary.uploads.images";
    }
    
    AWSS3GetPreSignedURLRequest* getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
    getPreSignedURLRequest.bucket = bucket;
    getPreSignedURLRequest.key = image.imagePath.lastPathComponent;
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:60*60*24];
    getPreSignedURLRequest.contentType = @"image/jpeg";
    
    AWSTask* awsTask = [[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:getPreSignedURLRequest];
    
    [awsTask continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        
        NSURL* presignedURL = awsTask.result;
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:presignedURL];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        [request setHTTPMethod:@"PUT"];
        [request setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        
        result(request);
        
        return nil;
        
    }];
}

- (void)createBookkeepingForImage:(MAPImage*)image
{
    //NSLog(@"create: %@", image.imagePath.lastPathComponent);
    
    NSString* scheduled = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".scheduled"];
    [[NSFileManager defaultManager] createFileAtPath:scheduled contents:nil attributes:nil];
}

- (void)deleteBookkeepingForImage:(MAPImage*)image
{
    //NSLog(@"delete: %@", image.imagePath.lastPathComponent);
    
    NSString* scheduled = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".scheduled"];
    NSString* processed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".processed"];
    NSString* done = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".done"];
    NSString* failed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".failed"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:scheduled])
    {
        [[NSFileManager defaultManager] removeItemAtPath:scheduled error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:processed])
    {
        [[NSFileManager defaultManager] removeItemAtPath:processed error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:done])
    {
        [[NSFileManager defaultManager] removeItemAtPath:done error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:failed])
    {
        [[NSFileManager defaultManager] removeItemAtPath:failed error:nil];
    }
}

- (void)setBookkeepingProcessedForImage:(MAPImage*)image
{
    //NSLog(@"processed: %@", image.imagePath.lastPathComponent);
    
    NSString* processed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".processed"];
    [[NSFileManager defaultManager] createFileAtPath:processed contents:nil attributes:nil];
}

- (void)setBookkeepingDoneForImage:(MAPImage*)image
{
    NSLog(@"done: %@", image.imagePath.lastPathComponent);
    
    NSString* done = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".done"];
    [[NSFileManager defaultManager] createFileAtPath:done contents:nil attributes:nil];
}

- (void)setBookkeepingFailedForImage:(MAPImage*)image
{
    NSLog(@"failed: %@", image.imagePath.lastPathComponent);
    
    NSString* failed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".failed"];
    [[NSFileManager defaultManager] createFileAtPath:failed contents:nil attributes:nil];
}

- (void)cleanUp
{
    // Delete bookkeeping
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:sequence.path])
        {
            for (MAPImage* image in [sequence getImages])
            {
                [self deleteBookkeepingForImage:image];
            }
            
            [sequence unlock];
        }
    }
}

- (void)calculateUploadSpeed
{
    NSDate* now = [NSDate date];
    NSTimeInterval time = [now timeIntervalSinceDate:self.dateLastUpdate];
    
    NSNumber* speedNow = [NSNumber numberWithDouble:self.bytesUploadedSinceLastUpdate/time];
    [self.speedArray addObject:speedNow];
    
    if (self.speedArray.count > 10)
    {
        [self.speedArray removeObjectAtIndex:0];
    }
    
    double sum = 0;
    
    for (NSNumber* s in self.speedArray)
    {
        sum += s.doubleValue;
    }
    
    self.status.uploadSpeedBytesPerSecond = (float)sum/(float)self.speedArray.count;
    
    self.dateLastUpdate = now;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadedData:bytesSent:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadedData:self bytesSent:self.bytesUploadedSinceLastUpdate status:self.status];
        });
    }
    
    self.bytesUploadedSinceLastUpdate = 0;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    /* TODO: Is this really needed?
     dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.backgroundUploadSessionCompletionHandler)
        {
            self.backgroundUploadSessionCompletionHandler();
            self.backgroundUploadSessionCompletionHandler = nil;
        }
    });*/
    
    if (self.status.uploading && self.delegate && [self.delegate respondsToSelector:@selector(uploadFinished:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadFinished:self status:self.status];
        });
    }
    
    self.status.uploading = NO;
    
    [self cleanUp];
    
    NSLog(@"All tasks are finished");
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    self.bytesUploadedSinceLastUpdate += bytesSent;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    NSString* filePath = task.taskDescription;
    MAPImage* image = [[MAPImage alloc] initWithPath:filePath];
    
    if (error == nil && task.state == NSURLSessionTaskStateCompleted)
    {
        if (self.deleteAfterUpload || (!self.testUpload && !self.deleteAfterUpload))
        {
            MAPSequence* sequence = [[MAPSequence alloc] initWithPath:[filePath stringByDeletingLastPathComponent] parseGpx:NO];
            [sequence deleteImage:image];
        }
        
        self.status.imagesUploaded++;
        
        [self setBookkeepingDoneForImage:image];
        
        if (self.status.uploading && self.delegate && [self.delegate respondsToSelector:@selector(imageUploaded:image:status:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate imageUploaded:self image:image status:self.status];
            });
        }
        
        //NSLog(@"Finished uploading %@", filePath.lastPathComponent);
    }
    else if (task.state != NSURLSessionTaskStateCanceling)
    {
        self.status.imagesFailed++;
        
        [self setBookkeepingFailedForImage:image];
        
        if (self.status.uploading && self.delegate && [self.delegate respondsToSelector:@selector(imageFailed:image:status:error:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate imageFailed:self image:image status:self.status error:error];
            });
        }
        
        NSLog(@"Error uploading %@, error: %@", filePath.lastPathComponent, [error localizedDescription]);
    }
    
    if (self.status.imagesUploaded+self.status.imagesFailed == self.status.imageCount)
    {
        if (self.status.uploading && self.delegate && [self.delegate respondsToSelector:@selector(uploadFinished:status:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadFinished:self status:self.status];
            });
        }
        
        [self.speedTimer invalidate];
        self.speedTimer = nil;
        
        self.status.uploading = NO;
        
        [self cleanUp];
    }
    else if (UPLOAD_MODE == FOREGROUND && self.imagesToUpload.count > 0 && self.status.uploading)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.status.uploading)
            {
                MAPImage* next = self.imagesToUpload.firstObject;
                [self.imagesToUpload removeObjectAtIndex:0];
                [self createTask:next];
            }
        });
    }
}

@end
