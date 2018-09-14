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

@interface MAPUploadManager()

@property (nonatomic) NSMutableArray* sequencesToUpload;
@property (nonatomic) MAPUploadManagerStatus* status;

@property (nonatomic) NSURLSession* backgroundSession;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundUpdateTask;

@property (nonatomic) NSTimer* speedTimer;
@property (nonatomic) NSDate* dateLastUpdate;
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
        
        self.status = [[MAPUploadManagerStatus alloc] init];
        self.dateLastUpdate = [NSDate date];
        self.bytesUploadedSinceLastUpdate = 0;
        self.allowsCellularAccess = NO;
        self.testUpload = NO;
        self.deleteAfterUpload = YES;
        
        [self setupAws];
        [self createSession];
        [self loadState];
    }
    
    return self;
}

- (void)processSequences:(NSArray*)sequences
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
    
    [self.sequencesToUpload removeAllObjects];
    [self.sequencesToUpload addObjectsFromArray:sequences];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (MAPSequence* sequence in self.sequencesToUpload)
        {
            self.status.imageCount += sequence.imageCount;
            [sequence lock];
        }
        
        [self startProcessing];
        
    });
}

- (void)processAndUploadSequences:(NSArray*)sequences
{
    if (self.status.processing || self.status.uploading)
    {
        return;
    }
    
    if (self.backgroundSession == nil || self.backgroundSession.configuration.allowsCellularAccess != self.allowsCellularAccess)
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
    
    self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(calculateSpeed) userInfo:nil repeats:YES];
    
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
    
    [self startUpload];
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
    self.status.uploading = NO;
    
    [self.backgroundSession invalidateAndCancel];
    self.backgroundSession = nil;

    [self.speedTimer invalidate];
    self.speedTimer = nil;
    
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        for (MAPImage* image in [sequence getImages])
        {
            [self deleteBookkeepingForImage:image];
        }
        
        [sequence unlock];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStopped:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadStopped:self status:self.status];
        });
    }
}

- (MAPUploadManagerStatus*)getStatus
{
    return self.status;
}

#pragma mark - internal

- (void)loadState
{
    [self.backgroundSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        
        self.status.uploading = NO;
        
        for (NSURLSessionTask* task in uploadTasks)
        {
            if (task.state == NSURLSessionTaskStateRunning)
            {
                self.status.uploading = YES;
                [task suspend];
            }
        }
        
        [MAPFileManager getSequencesAsync:YES done:^(NSArray *sequences) {
            
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
                        self.status.imageCount += scheduled.count + processed.count + done.count + failed.count;
                        self.status.imagesProcessed += processed.count + done.count + failed.count;
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
                        
                        self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(calculateSpeed) userInfo:nil repeats:YES];
                    }
                }
            }
            else
            {
                [self cleanUp];
            }
        }];
    }];
}

- (void)setupAws
{
    AWSRegionType region = AWSRegionEUWest1;
    AWSCognitoCredentialsProvider* credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:region identityPoolId:AWS_COGNITO_IDENTITY_POOL_ID];
    AWSServiceConfiguration* configuration = [[AWSServiceConfiguration alloc] initWithRegion:region credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

- (void)startUpload
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (MAPSequence* sequence in self.sequencesToUpload)
        {
            for (MAPImage* image in [sequence getImages])
            {
                if (!self.status.uploading)
                {
                    return;
                }
                
                [self createTask:image sequence:sequence];
            }
        }
        
    });
}

- (void)startProcessing
{
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        for (MAPImage* image in [sequence getImages])
        {
            if (!self.status.processing)
            {
                return;
            }
            
            [MAPExifTools addExifTagsToImage:image fromSequence:sequence];
            
            self.status.imagesProcessed++;
            
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

- (void)createSession
{
    if (self.backgroundSession)
    {
        [self.backgroundSession invalidateAndCancel];
        self.backgroundSession = nil;
    }
    
    NSURLSessionConfiguration* backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.mapillary.sdk.networking.upload"];
    backgroundConfiguration.allowsCellularAccess = self.allowsCellularAccess;
    backgroundConfiguration.timeoutIntervalForResource = 7*24*60*60;
    backgroundConfiguration.timeoutIntervalForRequest = 7*24*60*60;
    
    self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
}

- (void)createTask:(MAPImage*)image sequence:(MAPSequence*)sequence
{
    // Process image
    
    [MAPExifTools addExifTagsToImage:image fromSequence:sequence];
    
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

    // Create task and schedule for upload
    
    [self createRequestForImage:image request:^(NSURLRequest *request) {
        
        NSURLSessionUploadTask* uploadTask = [self.backgroundSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:image.imagePath]];
        
        [uploadTask setTaskDescription:image.imagePath];
        [uploadTask resume];

    }];
    
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
    
    NSString* upload = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".scheduled"];
    [[NSFileManager defaultManager] createFileAtPath:upload contents:nil attributes:nil];
}

- (void)deleteBookkeepingForImage:(MAPImage*)image
{
    //NSLog(@"delete: %@", image.imagePath.lastPathComponent);
    
    NSString* scheduled = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".scheduled"];
    NSString* processed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".processed"];
    NSString* done = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".done"];
    NSString* failed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".failed"];
    
    [[NSFileManager defaultManager] removeItemAtPath:scheduled error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:processed error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:done error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:failed error:nil];
}

- (void)setBookkeepingProcessedForImage:(MAPImage*)image
{
    //NSLog(@"processed: %@", image.imagePath.lastPathComponent);
    
    NSString* scheduled = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".scheduled"];
    NSString* processed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".processed"];
    [[NSFileManager defaultManager] moveItemAtPath:scheduled toPath:processed error:nil];
}

- (void)setBookkeepingDoneForImage:(MAPImage*)image
{
    NSLog(@"done: %@", image.imagePath.lastPathComponent);
    
    NSString* processed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".processed"];
    NSString* done = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".done"];
    [[NSFileManager defaultManager] moveItemAtPath:processed toPath:done error:nil];
}

- (void)setBookkeepingFailedForImage:(MAPImage*)image
{
    NSLog(@"failed: %@", image.imagePath.lastPathComponent);
    
    NSString* processed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".processed"];
    NSString* failed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".failed"];
    [[NSFileManager defaultManager] moveItemAtPath:processed toPath:failed error:nil];
}

- (void)calculateSpeed
{
    NSDate* now = [NSDate date];
    NSTimeInterval time = [now timeIntervalSinceDate:self.dateLastUpdate];
    
    float factor = 0.5;
    float lastSpeed = self.status.uploadSpeedBytesPerSecond;
    float averageSpeed = self.bytesUploadedSinceLastUpdate/time;
    self.status.uploadSpeedBytesPerSecond = factor*lastSpeed + (1-factor)*averageSpeed;
    
    self.dateLastUpdate = now;
    self.bytesUploadedSinceLastUpdate = 0;
}

- (void)cleanUp
{
    // Stop timer
    [self.speedTimer invalidate];
    self.speedTimer = nil;
    
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

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    [self cleanUp];
    
    if (self.backgroundUploadSessionCompletionHandler)
    {
        self.backgroundUploadSessionCompletionHandler();
        self.backgroundUploadSessionCompletionHandler = nil;
    }
    
    if (self.status.uploading && self.delegate && [self.delegate respondsToSelector:@selector(uploadFinished:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadFinished:self status:self.status];
        });
    }
    
     self.status.uploading = NO;
    
    NSLog(@"All tasks are finished");
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    self.bytesUploadedSinceLastUpdate += bytesSent;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadedData:bytesSent:status:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadedData:self bytesSent:bytesSent status:self.status];
        });
    }
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
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imageUploaded:image:status:)])
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
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imageFailed:image:status:error:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate imageFailed:self image:image status:self.status error:error];
            });
        }
        
        NSLog(@"Error uploading %@, error: %@", filePath.lastPathComponent, [error localizedDescription]);
    }
    
    if (self.status.imagesUploaded+self.status.imagesFailed == self.status.imageCount)
    {
        [self cleanUp];
        
        if (self.status.uploading && self.delegate && [self.delegate respondsToSelector:@selector(uploadFinished:status:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadFinished:self status:self.status];
            });
        }
        
        self.status.uploading = NO;
    }
}

@end
