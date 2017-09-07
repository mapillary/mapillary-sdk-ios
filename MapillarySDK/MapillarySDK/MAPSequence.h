//
//  MAPSequence.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPLocation.h"
#import "MAPDevice.h"

@interface MAPSequence : NSObject

@property CLLocationDirection directionOffset; // (-1 = undefined, 0-360 = set),
@property NSTimeInterval timeOffset; // in milliseconds, +1 means the image date is increased by 1 ms
@property NSDate* sequenceDate;
@property NSString* path;
@property NSString* project;
@property NSString* sequenceKey;
@property MAPDevice* device;
    
- (id)initWithDevice:(MAPDevice*)device;

- (NSArray*)listImages;
- (NSArray*)listLocations;
    
- (MAPLocation*)locationForDate:(NSDate*)date;
    
- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date location:(MAPLocation*)location;
- (void)addImageWithPath:(NSString*)imagePath date:(NSDate*)date location:(MAPLocation*)location;
- (void)addLocation:(MAPLocation*)location;
- (void)addGpx:(NSString*)path;

@end
