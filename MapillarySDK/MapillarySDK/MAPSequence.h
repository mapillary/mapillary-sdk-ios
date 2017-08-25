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
@property (nonnull) NSDate* sequenceDate;

- (nonnull NSArray*)listImages;
- (void)addImageWithData:(nonnull NSData*)imageData date:(nullable NSDate*)date bearing:(nullable NSNumber*)bearing location:(nullable MAPLocation*)location;
- (void)addImageWithPath:(nonnull NSString*)imagePath date:(nullable NSDate*)date bearing:(nullable NSNumber*)bearing location:(nullable MAPLocation*)location;
- (void)addLocation:(nonnull MAPLocation*)location date:(nonnull NSDate*)date;
- (void)addGpx:(nonnull NSString*)path;

@end
