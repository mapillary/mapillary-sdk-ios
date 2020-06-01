//
//  MAPUploadManagerDelegate.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-04-03.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUploadManagerStatus.h"

@class MAPUploadManager;

/**
 This protocol is used for notifying the delegate what's happening during
 image processing and upload.
 */
@protocol MAPUploadManagerDelegate <NSObject>

@optional

/**
 Delegate method for when an image is processed.
 
 @param uploadManager The upload manager object that is processing the image.
 @param image The image that has been processed.
 @param status The current status of the upload manager.
 */
- (void)imageProcessed:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status;

/**
 Delegate method for when all images have been processed.
 
 @param uploadManager The upload manager object that is processing the image.
 @param status The current status of the upload manager.
 */
- (void)processingFinished:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status;

/**
 Delegate method for when image processing has was stopped by calling stopProcessing.
 
 @param uploadManager The upload manager object that is processing the image.
 @param status The current status of the upload manager.
 */
- (void)processingStopped:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status;

/**
 Delegate method for when an image was sucessfully uploaded.
 
 @param uploadManager The upload manager object that is uploading the image.
 @param image The image that has been uploaded.
 @param status The current status of the upload manager.
 */
- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status;

/**
 Delegate method for when an image failed to upload.
 
 @param uploadManager The upload manager object that is uploading the image.
 @param image The image that failed to upload.
 @param status The current status of the upload manager.
 @param error The error explaining what went wrong.
 */
- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status error:(NSError*)error;

/**
 Delegate method for when a chunk of data has been uploaded.
 
 @param uploadManager The upload manager object that is uploading the images.
 @param bytesSent The number of bytes sent since the last invocation of this method.
 @param status The current status of the upload manager.
 */
- (void)uploadedData:(MAPUploadManager*)uploadManager bytesSent:(int64_t)bytesSent status:(MAPUploadManagerStatus*)status;

/**
 Delegate method for when all images have been uploaded.
 
 @param uploadManager The upload manager object that is uploading the images.
 @param status The current status of the upload manager.
 */
- (void)uploadFinished:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status;

/**
 Delegate method for when image uploading has was stopped by calling stopUpload.
 
 @param uploadManager The upload manager object that is uploading the images.
 @param status The current status of the upload manager.
 */
- (void)uploadStopped:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status;

/**
 Delegate method for when the upload service is not reachable.
 
 @param uploadManager The upload manager object that is uploading the images.
 @param status The current status of the upload manager.
 */
- (void)uploadServiceNotReachable:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status;

@end
