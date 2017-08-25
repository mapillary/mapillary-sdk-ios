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

@class MAPUploadManager;

@protocol MAPUploadManagerDelegate <NSObject>
@optional
- (void)uploadStarted:(nonnull MAPUploadManager*)uploadManager;
- (void)uploadStopped:(nonnull MAPUploadManager*)uploadManager;
- (void)imageUploadSuccess:(nonnull MAPUploadManager*)uploadManager image:(nonnull MAPImage*)image;
- (void)imageUploadFailed:(nonnull MAPUploadManager*)uploadManager image:(nonnull MAPImage*)image error:(nonnull NSError*)error;
@end

@interface MAPUploadManager : NSObject

@property (weak, nullable) id<MAPUploadManagerDelegate> delegate;
@property int nbrUploadThreads;
@property BOOL allowUploadOnCell;

- (void)uploadSequences:(nonnull NSArray*)sequences;
- (void)stopUpload;
- (nonnull MAPUploadStatus*)getStatus;


@end
