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

@interface NSObject (Associating)

@property (nonatomic, retain) id associatedObject;

@end

@implementation NSObject (Associating)

- (id)associatedObject
{
    return objc_getAssociatedObject(self, @selector(associatedObject));
}

- (void)setAssociatedObject:(id)associatedObject
{
    objc_setAssociatedObject(self, @selector(associatedObject), associatedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface MAPUploadManager()

@property (nonatomic) NSMutableArray* sequencesToUpload;
@property (nonatomic) MAPUploadStatus* status;
@property (nonatomic) BOOL deleteAfterUpload;

@property (copy, nonatomic) AWSS3TransferUtilityUploadCompletionHandlerBlock completionHandler;

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
        
        self.status = [[MAPUploadStatus alloc] init];
        
        [self setupAws];
        [self loadState];
    }
    
    return self;
}

- (void)uploadSequences:(NSArray*)sequences allowsCellularAccess:(BOOL)allowsCellularAccess deleteAfterUpload:(BOOL)deleteAfterUpload
{
    if (self.status.uploading)
    {
        return;
    }
    
    self.deleteAfterUpload = deleteAfterUpload;
    
    self.status.uploading = YES;
    self.status.imagesToUpload = 0;
    self.status.imagesUploaded = 0;
    self.status.imagesFailed = 0;
    self.status.imagesProcessed = 0;
    self.status.totalBytesSent = 0;
    self.status.totalBytesToSend = 0;
    
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration.allowsCellularAccess = allowsCellularAccess;
    
    [self.sequencesToUpload removeAllObjects];
    [self.sequencesToUpload addObjectsFromArray:sequences];
    
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        NSArray* images = [sequence listImages];
        self.status.imagesToUpload += images.count;
        
        for (MAPImage* image in images)
        {
            [self createBookkeepingForImage:image];
        }
        
        [sequence lock];
    }
    
    [self start];
}

- (void)stopUpload
{
    AWSS3TransferUtility* transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    
    [transferUtility enumerateToAssignBlocksForUploadTask:^(AWSS3TransferUtilityUploadTask * _Nonnull uploadTask, AWSS3TransferUtilityProgressBlock  _Nullable __autoreleasing * _Nullable uploadProgressBlockReference, AWSS3TransferUtilityUploadCompletionHandlerBlock  _Nullable __autoreleasing * _Nullable completionHandlerReference) {
        
        [uploadTask cancel];
        
    } downloadTask:nil];
    
    self.status.uploading = NO;
    
    for (MAPSequence* sequence in self.sequencesToUpload)
    {
        for (MAPImage* image in [sequence listImages])
        {
            [self deleteBookkeepingForImage:image];
        }
        
        [sequence unlock];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStopped:uploadStatus:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadStopped:self uploadStatus:[self getStatus]];
        });
    }
}

- (MAPUploadStatus*)getStatus
{
    return self.status;
}

#pragma mark - internal

- (void)loadState
{
    // TODO pause
    
    [MAPFileManager listSequences:^(NSArray *sequences) {
        
        for (MAPSequence* sequence in sequences)
        {
            if ([sequence isLocked])
            {
                [self.sequencesToUpload addObject:sequence];
                
                NSArray* dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sequence.path error:nil];
                
                NSArray* images = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF ENDSWITH '.jpg') AND (NOT SELF CONTAINS 'thumb')"]];
                NSArray* done = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.done'"]];
                NSArray* failed = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.failed'"]];
                
                self.status.uploading = YES;
                self.status.imagesToUpload += images.count;
                self.status.imagesUploaded += done.count;
                self.status.imagesFailed += failed.count;
                
                // TODO count bytes
            }
        }
        
        // TODO resume
    }];
}

- (void)saveState
{
    
}

- (void)setupAws
{
    // Configure AWS
    
    AWSRegionType region = AWSRegionEUWest1;
    AWSCognitoCredentialsProvider* credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:region identityPoolId:AWS_COGNITO_IDENTITY_POOL_ID];
    AWSServiceConfiguration* configuration = [[AWSServiceConfiguration alloc] initWithRegion:region credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    
    
    // Setup transfer utility
    
    AWSS3TransferUtility* transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    __weak MAPUploadManager* weakSelf = self;
    
    self.completionHandler = ^(AWSS3TransferUtilityUploadTask *task, NSError *error) {
        
        NSString* filePath = [task associatedObject];
        
        if (filePath)
        {
            MAPImage* image = [[MAPImage alloc] initWithPath:filePath];
            
            if (!error)
            {
                weakSelf.status.imagesUploaded++;
                weakSelf.status.totalBytesToSend += task.sessionTask.countOfBytesSent;
                
                [weakSelf setBookkeepingDoneForImage:image];
                
                if (weakSelf.deleteAfterUpload)
                {
                    MAPSequence* sequence = [[MAPSequence alloc] initWithPath:[filePath stringByDeletingLastPathComponent]];
                    [sequence deleteImage:image];
                    
                    NSArray* imagesLeft = [sequence listImages];
                    if (imagesLeft.count == 0)
                    {
                        [MAPFileManager deleteSequence:sequence];
                    }
                }
            }
            else
            {
                weakSelf.status.imagesFailed++;
                
                [weakSelf setBookkeepingFailedForImage:image];
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(imageUploaded:image:uploadStatus:error:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate imageUploaded:weakSelf image:image uploadStatus:[weakSelf getStatus] error:error];
                });
            }
            
            if (self.status.imagesUploaded+self.status.imagesFailed == self.status.imagesToUpload)
            {
                weakSelf.status.uploading = NO;
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploadFinished:uploadStatus:)])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.delegate uploadFinished:weakSelf uploadStatus:[weakSelf getStatus]];
                    });
                }
            }
        }
    };
    
    [transferUtility enumerateToAssignBlocksForUploadTask:^(AWSS3TransferUtilityUploadTask * _Nonnull uploadTask, AWSS3TransferUtilityProgressBlock  _Nullable __autoreleasing * _Nullable uploadProgressBlockReference, AWSS3TransferUtilityUploadCompletionHandlerBlock  _Nullable __autoreleasing * _Nullable completionHandlerReference) {
        
        *completionHandlerReference = weakSelf.completionHandler;
        
        
    } downloadTask:nil];
}

- (void)upload:(MAPImage*)image fromSequence:(MAPSequence*)sequence
{
    NSURL* url = [NSURL fileURLWithPath:image.imagePath];
    NSString* key = image.imagePath.lastPathComponent;
    NSString* contentType = @"image/jpeg";
    NSString* bucket = nil;
    
    if (self.testUpload)
    {
        bucket = @"test.balda.public.bucket";
    }
    else
    {
        bucket = @"mapillary.uploads.images";
    }
    
    AWSS3TransferUtilityUploadExpression* expression = [AWSS3TransferUtilityUploadExpression new];
    
    AWSS3TransferUtility* transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    
    AWSTask<AWSS3TransferUtilityUploadTask*>* awsTask = [transferUtility uploadFile:url bucket:bucket key:key contentType:contentType expression:expression completionHandler:self.completionHandler];
    AWSS3TransferUtilityUploadTask* uploadTask = awsTask.result;
    [uploadTask setAssociatedObject:image.imagePath];
    
    [awsTask continueWithBlock:^id _Nullable(AWSTask<AWSS3TransferUtilityUploadTask *> * _Nonnull t) {
        
        if (t.error)
        {
            NSLog(@"Error: %@", t.error);
        }
        
        /*AWSS3TransferUtilityUploadTask* uploadTask = t.result;
        if (uploadTask.sessionTask.state == NSURLSessionTaskStateRunning)
        {
            NSString* imagePath = [uploadTask associatedObject];
            
            if (imagePath)
            {
                MAPImage* image = [[MAPImage alloc] initWithPath:imagePath];
                [self setBookkeepingUploadingForImage:image];
            }
        }*/
        
        return nil;
        
    }];
}

- (void)start
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //NSDate* start = [NSDate date];
        
        BOOL notifiedUploadStart = NO;
        
        for (MAPSequence* sequence in self.sequencesToUpload)
        {
            for (MAPImage* image in [sequence listImages])
            {
                // Process images
                [MAPExifTools addExifTagsToImage:image fromSequence:sequence];
                self.status.imagesProcessed++;
                
                NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:image.imagePath error:nil];
                if (attrs != nil)
                {
                    NSNumber* fileSize = [attrs objectForKey:@"NSFileSize"];
                    self.status.totalBytesToSend += fileSize.integerValue;
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(imageProcessed:image:uploadStatus:)])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate imageProcessed:self image:image uploadStatus:[self getStatus]];
                    });
                }
                
                // Schedule upload
                [self upload:image fromSequence:sequence];
                
                if (!notifiedUploadStart)
                {
                    notifiedUploadStart = YES;
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStarted:uploadStatus:)])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate uploadStarted:self uploadStatus:[self getStatus]];
                        });
                    }
                }
            }
        }
        
        /*NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:start];
        float speed = self.status.imagesToUpload/time;*/

    });
}

- (void)createBookkeepingForImage:(MAPImage*)image
{
    NSLog(@"create: %@", image.imagePath.lastPathComponent);
    
    NSString* upload = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".upload"];
    [[NSFileManager defaultManager] createFileAtPath:upload contents:nil attributes:nil];
}

- (void)deleteBookkeepingForImage:(MAPImage*)image
{
    NSLog(@"delete: %@", image.imagePath.lastPathComponent);
    
    NSString* upload = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".upload"];
    NSString* done = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".done"];
    NSString* failed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".failed"];
    
    [[NSFileManager defaultManager] removeItemAtPath:upload error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:done error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:failed error:nil];
}

- (void)setBookkeepingDoneForImage:(MAPImage*)image
{
    NSLog(@"done: %@", image.imagePath.lastPathComponent);
    
    NSString* upload = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".upload"];
    NSString* done = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".done"];
    [[NSFileManager defaultManager] moveItemAtPath:upload toPath:done error:nil];
}

- (void)setBookkeepingFailedForImage:(MAPImage*)image
{
    NSLog(@"failed: %@", image.imagePath.lastPathComponent);
    
    NSString* upload = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".upload"];
    NSString* failed = [image.imagePath stringByReplacingOccurrencesOfString:@".jpg" withString:@".failed"];
    [[NSFileManager defaultManager] moveItemAtPath:upload toPath:failed error:nil];
}

@end
