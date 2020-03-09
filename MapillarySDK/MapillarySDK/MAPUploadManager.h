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

@property (nonatomic, copy) void (^backgroundUploadSessionCompletionHandler)(void);

///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 The delegate of the upload manager object.
 */
@property (weak) id<MAPUploadManagerDelegate> delegate;

/**
 Set this property to YES if you want to test your upload. It uploads to a test
 server instead of the production server. Images on this server are not
 accessible and will be deleted.
 
 Default is NO.
 */
@property (nonatomic) BOOL testUpload;

/**
 Set this property to NO if you want to keep your local images efter they have been
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

/**
 Controls the number of files that are uploaded simultaneously. Set this before
 starting an upload.
 
 Default is 4.
 */
@property (nonatomic) int numberOfSimultaneousUploads;

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
 Process the image received as parameter
 */
- (void)processImage:(MAPImage*)image sequence:(MAPSequence*)sequence forceProcessing:(BOOL)forceProcessing;

/**
 Stops the image processing.
 */
- (void)stopProcessing;

///-----------------------------------------------------------------------------
/// @name Starting and stopping image uploading
///-----------------------------------------------------------------------------

/**
 Starts to process and upload the sequences in the array. As soon as
 one image has finished processing, it will be scheduled for uploading.
 
 @param forceReprocessing If set to YES, images that are already processed will
 be processed again. This is needed if you change GPX data, like the offset etc.
 If set to NO, images that already have been processed will not be processed
 again.
 */
- (void)processAndUploadSequences:(NSArray*)sequences forceReprocessing:(BOOL)forceReprocessing;

/**
 Starts to upload the sequences in the array. If the images haven't been
 processed using `processSequences`, they will be processed before uploading.
 */
- (void)uploadSequences:(NSArray*)sequences;

/**
 Stops the image processing and upload.
 */
- (void)stopUpload;

/**
 Starts the image processing.
 */
- (void)startProcessing:(BOOL)forceReprocessing;

/**
 Starts the image upload.
 */
- (void)startUpload:(BOOL)forceProcessing;

/**
 Creates book keeping for an image
 */
- (void)createBookkeepingForImage:(MAPImage*)image;

/**
 Creates an upload sesion
 */
- (void)createSession;

/**
 Gets the upload session
 */
- (NSURLSession*)getSession;

/**
 Calculates the upload speed
 */
- (void)calculateUploadSpeed;


///-----------------------------------------------------------------------------
/// @name Getting the current status of the Upload Manager
///-----------------------------------------------------------------------------

/**
 Returns the current status of the Upload Manager.
 
 @return The current status of the Upload Manager.
 */
- (MAPUploadManagerStatus*)getStatus;

@end
