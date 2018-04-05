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
 
 Default is NO.
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
 */
- (void)processSequences:(NSArray*)sequences;

/**
 Stops the image processing.
 */
- (void)stopProcessing;

///-----------------------------------------------------------------------------
/// @name Starting and stopping image uploading
///-----------------------------------------------------------------------------

/**
 Starts to process and upload the sequences in the array.
 */
- (void)processAndUploadSequences:(NSArray*)sequences;

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
- (MAPUploadStatus*)getStatus;

@end
