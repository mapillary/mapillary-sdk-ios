//
//  MAPUploadManagerDelegate.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-04-03.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUploadStatus.h"

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
 @param uploadStatus The current status of the upload manager.
 */
- (void)imageProcessed:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus;

/**
 Delegate method for when all images have been processed.
 
 @param uploadManager The upload manager object that is processing the image.
 @param uploadStatus The current status of the upload manager.
 */
- (void)processingFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;

/**
 Delegate method for when image processing has was stopped by calling stopProcessing.
 
 @param uploadManager The upload manager object that is processing the image.
 @param uploadStatus The current status of the upload manager.
 */
- (void)processingStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;

/**
 Delegate method for when an image was sucessfully uploaded.
 
 @param uploadManager The upload manager object that is uploading the image.
 @param image The image that has been uploaded.
 @param uploadStatus The current status of the upload manager.
 */
- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus;

/**
 Delegate method for when an image failed to upload.
 
 @param uploadManager The upload manager object that is uploading the image.
 @param image The image that failed to upload.
 @param uploadStatus The current status of the upload manager.
 @param error The error explaining what went wrong.
 */
- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus error:(NSError*)error;

/**
 Delegate method for when a chunk of data has been uploaded.
 
 @param uploadManager The upload manager object that is uploading the images.
 @param bytesSent The number of bytes sent since the last invocation of this method.
 @param uploadStatus The current status of the upload manager.
 */
- (void)uploadedData:(MAPUploadManager*)uploadManager bytesSent:(int64_t)bytesSent uploadStatus:(MAPUploadStatus*)uploadStatus;

/**
 Delegate method for when all images have been uploaded.
 
 @param uploadManager The upload manager object that is uploading the images.
 @param uploadStatus The current status of the upload manager.
 */
- (void)uploadFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;

/**
 Delegate method for when image uploading has was stopped by calling stopUpload.
 
 @param uploadManager The upload manager object that is uploading the images.
 @param uploadStatus The current status of the upload manager.
 */
- (void)uploadStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus;
@end
