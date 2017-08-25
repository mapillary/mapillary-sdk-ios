//
//  MAPSequence.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPSequence.h"

@implementation MAPSequence

- (id)init
{
    self = [super init];
    if (self)
    {
        self.sequenceDate = [NSDate date];
        self.bearingOffset = -1;
        self.timeOffset = 0;
    }
    return self;
}

- (NSArray*)listImages
{
    NSArray* images = [[NSArray alloc] init];
    return images;
}

- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date bearing:(NSNumber*)bearing location:(MAPLocation*)location
{

}

- (void)addImageWithPath:(NSString*)imagePath date:(NSDate*)date bearing:(NSNumber*)bearing location:(MAPLocation*)location
{

}

- (void)addLocation:(MAPLocation*)location date:(NSDate*)date
{

}

- (void)addGpx:(NSString*)path
{

}

@end
