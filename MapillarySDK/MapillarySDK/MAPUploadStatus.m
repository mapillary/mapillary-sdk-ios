//
//  MAPUploadStatus.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUploadStatus.h"

@implementation MAPUploadStatus

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.uploading = NO;
        self.imagesToUpload = 0;
        self.imagesUploaded = 0;
        self.imagesFailed = 0;
        self.imagesProcessed = 0;
        self.uploadSpeedBytesPerSecond = 0;
    }
    return self;
}

@end
