//
//  MAPUploadStatus.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The `MAPUploadStatus` class encapsulates the information about the upload
 progress.
*/
@interface MAPUploadStatus : NSObject

/**
 The upload status that defines if we are currently uploading or not.
 */
@property (nonatomic) BOOL uploading;

/**
 The processing status that defines if we are currently processing or not.
 */
@property (nonatomic) BOOL processing;

/**
 Number of images scheduled to upload.
 */
@property (nonatomic) NSUInteger imageCount;

/**
 Number of images that have been sucessfully uploaded.
 */
@property (nonatomic) NSUInteger imagesUploaded;

/**
 Number of images that failed to uploaded.
 */
@property (nonatomic) NSUInteger imagesFailed;

/**
 Number of images that have been processed.
 */
@property (nonatomic) NSUInteger imagesProcessed;

/**
 The current upload speed in bytes/s.
 */
@property (nonatomic) float uploadSpeedBytesPerSecond;

@end
