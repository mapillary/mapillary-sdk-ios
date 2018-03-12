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

@protocol MAPUploadManagerDelegate <NSObject>
@optional
- (void)imageProcessed:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)processingFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)processingStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus error:(NSError*)error;
- (void)uploadedData:(MAPUploadManager*)uploadManager bytesSent:(int64_t)bytesSent uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)uploadFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)uploadStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
@end

@interface MAPUploadManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, CLLocationManagerDelegate>

@property (weak) id<MAPUploadManagerDelegate> delegate;
@property (nonatomic) BOOL testUpload;
@property (nonatomic) BOOL deleteAfterUpload;
@property (nonatomic) BOOL allowsCellularAccess;
@property (copy, nonatomic) void (^backgroundUploadSessionCompletionHandler)(void);

+ (instancetype)sharedManager;

- (void)processSequences:(NSArray*)sequences;
- (void)processAndUploadSequences:(NSArray*)sequences;
- (void)stopProcessing;
- (void)stopUpload;

- (MAPUploadStatus*)getStatus;

@end
