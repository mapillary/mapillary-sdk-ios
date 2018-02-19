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

#define UPLOAD_MODE_FOREGROUND  1
#define UPLOAD_MODE_BACKGROUND  2
#define AWS_IDENTITY_POOL_ID    @"eu-west-1:57d09467-4c2f-470d-9577-90d3f89f76a1"
#define DEBUG_UPLOAD YES

@interface MAPUploadManager()

@property (nonatomic) int uploadMode;
//@property (nonatomic) NSURLSession* foregroundSession;
@property (nonatomic) NSURLSession* backgroundSession;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundUpdateTask;
@property (nonatomic, copy) void (^savedCompletionHandler)(void);
//@property (nonatomic) NSMutableArray* imagesToUpload;
@property (nonatomic) NSMutableArray* sequencesToUpload;
@property (nonatomic) MAPUploadStatus* status;

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
        self.uploadMode = UPLOAD_MODE_BACKGROUND;
        //self.imagesToUpload = [NSMutableArray array];
        self.sequencesToUpload = [NSMutableArray array];
        self.status = [[MAPUploadStatus alloc] init];
        
        [self setupAws];
        [self loadState];
    }
    
    return self;
}

- (void)uploadSequences:(NSArray*)sequences allowsCellularAccess:(BOOL)allowsCellularAccess
{
    if (self.status.uploading)
    {
        return;
    }
    
    [self createSessions:allowsCellularAccess];
    
    //[self.imagesToUpload removeAllObjects];
    [self.sequencesToUpload removeAllObjects];
    
    [self.sequencesToUpload addObjectsFromArray:sequences];
    
    int count = 0;
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        NSArray* images = [sequence listImages];
        //[self.imagesToUpload addObjectsFromArray:images];
        count += images.count;
        
        [sequence lock];
    }
    
    self.status.imagesToUpload = count;
    self.status.sequencesToUpload = self.sequencesToUpload.count;
    
    [self startUpload];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStarted:uploadStatus:)])
    {
        [self.delegate uploadStarted:self uploadStatus:[self getStatus]];
    }
}

- (void)stopUpload
{
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        [sequence unlock];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStopped:uploadStatus:)])
    {
        [self.delegate uploadStopped:self uploadStatus:[self getStatus]];
    }
}

- (MAPUploadStatus*)getStatus
{
    return self.status;
}

#pragma mark - internal

- (void)loadState
{
    /*[MAPFileManager listSequences:^(NSArray *sequences) {
       
        for (MAPSequence* sequence in sequences)
        {
            if ([sequence isLocked])
            {
                [self.sequencesToUpload addObject:sequence];
                [self.imagesToUpload addObjectsFromArray:[sequence listImages]];
                self.status.uploading = YES;
            }
        }
    }];*/
}

- (void)saveState
{
    
}

- (void)setupAws
{
    AWSRegionType region = AWSRegionEUWest1; // Default to EU West 1
    AWSCognitoCredentialsProvider* credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:region identityPoolId:AWS_IDENTITY_POOL_ID];
    AWSServiceConfiguration* configuration = nil;
    
    if (DEBUG_UPLOAD)
    {
        AWSEndpoint* endpoint = [[AWSEndpoint alloc] initWithURLString:@"http://34.244.228.197:4569"];
        configuration = [[AWSServiceConfiguration alloc] initWithRegion:region endpoint:endpoint credentialsProvider:credentialsProvider];
    }
    else
    {
        configuration = [[AWSServiceConfiguration alloc] initWithRegion:region credentialsProvider:credentialsProvider];
    }
    
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

- (void)createSessions:(BOOL)allowsCellularAccess
{
    // Ensures we only create session once
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        // Foreground session
        /*NSURLSessionConfiguration* foregroundConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        foregroundConfiguration.allowsCellularAccess = [Settings uploadViaCellular];
        foregroundConfiguration.timeoutIntervalForResource = 7*24*60*60;
        foregroundConfiguration.timeoutIntervalForRequest = 7*24*60*60;
        self.foregroundSession = [NSURLSession sessionWithConfiguration:foregroundConfiguration delegate:self delegateQueue:nil];*/
        
        // Background session
        NSURLSessionConfiguration* backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.mapillary.networking.upload"];
        backgroundConfiguration.allowsCellularAccess = allowsCellularAccess;
        backgroundConfiguration.timeoutIntervalForResource = 7*24*60*60;
        backgroundConfiguration.timeoutIntervalForRequest = 7*24*60*60;
        self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
        
    });
    
    self.backgroundSession.configuration.allowsCellularAccess = allowsCellularAccess;
}

- (void)createTaskForImage:(MAPImage*)image fromSequence:(MAPSequence*)sequence
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    BOOL ok = [self checkImage:image fromSequence:sequence];
    
    if (ok)
    {
        [self createRequestForImage:image request:^(NSURLRequest *request) {
            
            NSURLSessionUploadTask* uploadTask = [self.backgroundSession uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:image.imagePath]];
            [uploadTask setTaskDescription:image.imagePath];
            [uploadTask resume];
            
            dispatch_semaphore_signal(sema);
            
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
}

- (void)createRequestForImage:(MAPImage*)image request:(void (^) (NSURLRequest* request))result
{
    NSString* bucket = nil;
    
    if (DEBUG_UPLOAD)
    {
        //bucket = @"mapillary.testing.uploads.images";
        bucket = @"mtf_upload_images";
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

- (BOOL)checkImage:(MAPImage*)image fromSequence:(MAPSequence*)sequence
{
    if (![MAPExifTools imageHasMapillaryTags:image])
    {
        [MAPExifTools addExifTagsToImage:image fromSequence:sequence];
    }
    
    return YES;
}

- (void)startUpload
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        for (MAPSequence* sequence in self.sequencesToUpload)
        {
            for (MAPImage* image in [sequence listImages])
            {
                [self createTaskForImage:image fromSequence:sequence];
                
                NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:image.imagePath error:nil];
                if (attrs != nil)
                {
                    NSNumber* fileSize = [attrs objectForKey:@"NSFileSize"];
                    self.status.totalKilobytesToSend += fileSize.integerValue/1024.0;
                }
            }
        }
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        
        //[self saveState];
        //exit(0);
    });
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    self.status.imagesUploaded = self.status.imagesToUpload;
    self.status.uploading = NO;
    
    if (self.savedCompletionHandler)
    {
        self.savedCompletionHandler();
        self.savedCompletionHandler = nil;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadFinished:uploadStatus:)])
    {
        [self.delegate uploadFinished:self uploadStatus:[self getStatus]];
    }
    
    NSLog(@"All tasks are finished");
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    self.status.totalKilobytesSent += bytesSent/1024.0;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    NSString* filePath = task.taskDescription;
    MAPImage* image = [[MAPImage alloc] initWithPath:filePath];
    
    if (error == nil && task.state == NSURLSessionTaskStateCompleted)
    {
        // Delete files
        [image delete];
        
        // Update counter
        self.status.imagesUploaded++;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imageUploaded:image:uploadStatus:error:)])
        {
            [self.delegate imageUploaded:self image:image uploadStatus:[self getStatus] error:nil];
        }
        
        NSLog(@"Finished uploading %@", filePath.lastPathComponent);
    }
    else //if (!self.switchingMode)
    {
        // Update counter
        self.status.imagesFailed++;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imageUploaded:image:uploadStatus:error:)])
        {
            [self.delegate imageUploaded:self image:image uploadStatus:[self getStatus] error:error];
        }
        
        NSLog(@"Error uploading %@, error: %@", filePath.lastPathComponent, [error localizedDescription]);
    }
}

@end
