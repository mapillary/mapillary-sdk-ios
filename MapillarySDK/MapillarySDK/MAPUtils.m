//
//  MAPUtils.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-10-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUtils.h"
#import "MAPInternalUtils.h"
#import "BOSImageResizeOperation.h"

@implementation MAPUtils

+ (void)createThumbnailForImage:(UIImage*)sourceImage atPath:(NSString*)path withSize:(CGSize)size
{
    BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:sourceImage];
    [op resizeToFitWithinSize:size];
    op.JPEGcompressionQuality = 0.5;
    [op writeResultToPath:path];
    [op start];
}

@end
