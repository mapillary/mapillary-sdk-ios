//
//  MAPUploadStatus.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPUploadStatus : NSObject

@property (nonatomic) BOOL uploading;
@property (nonatomic) NSUInteger imagesToUpload;
@property (nonatomic) NSUInteger imagesUploaded;
@property (nonatomic) NSUInteger imagesFailed;
@property (nonatomic) NSUInteger imagesProcessed;
@property (nonatomic) float uploadSpeedBytesPerSecond;

@end
