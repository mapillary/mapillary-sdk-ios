//
//  MAPSequence.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPSequence.h"
#import "Utils.h"

@interface MAPSequence()

@end

@implementation MAPSequence

- (id)init
{
    self = [super init];
    if (self)
    {
        self.sequenceDate = [NSDate date];
        self.bearingOffset = -1;
        self.timeOffset = 0;
        
        NSString* folderName = [Utils getTimeString];
        self.path = [NSString stringWithFormat:@"%@/%@", [Utils sequenceDirectory], folderName];
        
        [Utils createFolderAtPath:self.path];
    }
    return self;
}

- (NSArray*)listImages
{
    // TODO
    
    NSArray* images = [[NSArray alloc] init];
    return images;
}

- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date bearing:(NSNumber*)bearing location:(MAPLocation*)location
{
    // TODO
}

- (void)addImageWithPath:(NSString*)imagePath date:(NSDate*)date bearing:(NSNumber*)bearing location:(MAPLocation*)location
{
    // TODO
}

- (void)addLocation:(MAPLocation*)location date:(NSDate*)date
{
    // TODO
}

- (void)addGpx:(NSString*)path
{
    // TODO
}

@end
