//
//  MAPUploadManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUploadStatus.h"
#import "MAPImage.h"
#import "MAPSequence.h"

@class MAPUploadManager;

//typedef void (^MAPUploadManagerUploadCompletionHandlerBlock)(void);

@protocol MAPUploadManagerDelegate <NSObject>
@optional
- (void)imageProcessed:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus error:(NSError*)error;
- (void)uploadFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)uploadStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
@end

@interface MAPUploadManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, CLLocationManagerDelegate>

@property (weak) id<MAPUploadManagerDelegate> delegate;
@property (nonatomic) BOOL testUpload;
@property (copy, nonatomic) void (^backgroundUploadSessionCompletionHandler)(void);

+ (instancetype)sharedManager;

- (void)uploadSequences:(NSArray*)sequences allowsCellularAccess:(BOOL)allowsCellularAccess deleteAfterUpload:(BOOL)deleteAfterUpload;
- (void)stopUpload;

- (MAPUploadStatus*)getStatus;

@end
