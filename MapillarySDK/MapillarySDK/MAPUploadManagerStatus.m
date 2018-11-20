//
//  MAPUploadManagerStatus.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUploadManagerStatus.h"

@implementation MAPUploadManagerStatus

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.uploading = NO;
        self.processing = NO;
        self.imageCount = 0;
        self.imagesUploaded = 0;
        self.imagesFailed = 0;
        self.imagesProcessed = 0;
        self.uploadSpeedBytesPerSecond = 0;
    }
    return self;
}

@end
