//
//  MAPSequence.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPLocation.h"

@interface MAPSequence : NSObject

@property float bearingOffset; // (-1 = undefined, 0-360 = set),
@property NSTimeInterval timeOffset; // in milliseconds, +1 means the image date is increased by 1 ms
@property NSDate* captureDate;

- (NSArray*)listImages;
- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date bearing:(double)bearing location:(MAPLocation*)location;
- (void)addImageWithPath:(NSString*)imagePath date:(NSDate*)date bearing:(double)bearing location:(MAPLocation*)location;
- (void)addLocation:(MAPLocation*)location date:(NSDate*)date;
- (void)addGpx:(NSString*)path;

@end
