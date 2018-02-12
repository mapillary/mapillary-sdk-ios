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
- (void)uploadStarted:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus error:(NSError*)error;
- (void)sequenceFinished:(MAPUploadManager*)uploadManager sequence:(MAPSequence*)sequence uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)uploadFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
- (void)uploadStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
@end

@interface MAPUploadManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, CLLocationManagerDelegate>

@property (weak) id<MAPUploadManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)uploadSequences:(NSArray*)sequences allowsCellularAccess:(BOOL)allowsCellularAccess;
- (void)stopUpload;

- (MAPUploadStatus*)getStatus;

@end
