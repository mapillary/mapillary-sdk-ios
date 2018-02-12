//
//  MAPUploadStatus.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPUploadStatus : NSObject

@property BOOL uploading;
@property NSUInteger sequencesToUpload;
@property NSUInteger sequencesUploaded;
@property NSUInteger imagesToUpload;
@property NSUInteger imagesUploaded;
@property NSUInteger imagesFailed;
@property (nonatomic) float uploadSpeed;
@property (nonatomic) int64_t totalKilobytesSent;
@property (nonatomic) int64_t totalKilobytesToSend;

@end
