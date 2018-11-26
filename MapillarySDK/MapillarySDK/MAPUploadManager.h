//
//  MAPUploadManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUploadManagerStatus.h"
#import "MAPImage.h"
#import "MAPSequence.h"
#import "MAPUploadManagerDelegate.h"


/**
 The `MAPUploadManager` class handles both image processing and uploading.
 */
@interface MAPUploadManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, CLLocationManagerDelegate>

///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 The delegate of the upload manager object.
 */
@property (weak) id<MAPUploadManagerDelegate> delegate;

/**
 Set this flag to YES if you want to test your upload. It uploads to a test
 server instead of the production server. Images on this server is not
 accessible and will be deleted.
 
 Default is NO.
 */
@property (nonatomic) BOOL testUpload;

/**
 Set this flag to NO if you want to keep your local images efter they have been
 uploaded. This flag is only used if `testUpload` is set to YES. When uploading
 to the production servers images are always deleted to avoid duplicates.
 
 Default is YES.
 */
@property (nonatomic) BOOL deleteAfterUpload;

/**
 Set this flag to YES if you want to allow uploads via cellular network.
 
 Default is YES.
 */
@property (nonatomic) BOOL allowsCellularAccess;

///-----------------------------------------------------------------------------
/// @name Creating an Upload Manager
///-----------------------------------------------------------------------------

/**
 Returns the shared upload manager object.
 
 @return The shared upload manager.
 */
+ (instancetype)sharedManager;

///-----------------------------------------------------------------------------
/// @name Starting and stopping image processing
///-----------------------------------------------------------------------------

/**
 Starts to process the sequences in the array.
 
 @param forceReprocessing If set to YES, images that are already processed will
 be processed again. This is needed if you change GPX data, like the offset etc.
 If set to NO, images that already have been processed will not be processed
 again.
 */
- (void)processSequences:(NSArray*)sequences forceReprocessing:(BOOL)forceReprocessing;

/**
 Stops the image processing.
 */
- (void)stopProcessing;

///-----------------------------------------------------------------------------
/// @name Starting and stopping image uploading
///-----------------------------------------------------------------------------

/**
 Starts to process and upload the sequences in the array. Even if the images
 has been processed before, it will be reprocessed before uploading. As soon as
 one image has finished processing, it will be scheduled for uploading.
 */
- (void)processAndUploadSequences:(NSArray*)sequences;

/**
 Starts to upload the sequences in the array. If the images haven't been
 processed using `processSequences`, they will be processed before uploading.
 */
- (void)uploadSequences:(NSArray*)sequences;

/**
 Stops the image processing and upload.
 */
- (void)stopUpload;

///-----------------------------------------------------------------------------
/// @name Getting the current status of the Upload Manager
///-----------------------------------------------------------------------------

/**
 Returns the current status of the Upload Manager.
 
 @return The current status of the Upload Manager.
 */
- (MAPUploadManagerStatus*)getStatus;

@end
