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
- (void)uploadStarted:(MAPUploadManager*)uploadManager;
- (void)uploadStopped:(MAPUploadManager*)uploadManager;
- (void)imageUploadSuccess:(MAPUploadManager*)uploadManager image:(MAPImage*)image;
- (void)imageUploadFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image error:(NSError*)error;
@end

@interface MAPUploadManager : NSObject

@property (weak) id<MAPUploadManagerDelegate> delegate;
@property int nbrUploadThreads;
@property BOOL allowUploadOnCell;

- (void)uploadSequences:(NSArray*)sequences;
- (void)stopUpload;
- (MAPUploadStatus*)getStatus;


@end
