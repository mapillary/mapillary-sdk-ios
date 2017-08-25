//
//  MAPUploadManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUploadManager.h"

@implementation MAPUploadManager

- (void)uploadSequences:(NSArray*)sequences
{
    // TODO
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStarted:)])
    {
        [self.delegate uploadStarted:self];
    }
}

- (void)stopUpload
{
    // TODO
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadStopped:)])
    {
        [self.delegate uploadStopped:self];
    }
}

- (MAPUploadStatus*)getStatus
{
    // TODO
    
    MAPUploadStatus* status = [[MAPUploadStatus alloc] init];
    status.nbrImagesToUpload = 0;
    status.nbrImagesUploaded = 0;
    status.uploading = NO;
    
    return status;
}

@end
