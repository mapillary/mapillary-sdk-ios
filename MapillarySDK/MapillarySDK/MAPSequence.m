//
//  MAPSequence.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPSequence.h"
#import "MAPUtils.h"
#import "MAPImage.h"
#import "MAPLoginManager.h"
#import "GpxLogger.h"

@interface MAPSequence()

@property NSString* sequenceUUID;
@property GpxLogger* gpxLogger;

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
        self.sequenceUUID = [[NSUUID UUID] UUIDString];
        
        NSString* folderName = [MAPUtils getTimeString];
        self.path = [NSString stringWithFormat:@"%@/%@", [MAPUtils sequenceDirectory], folderName];
        
        [MAPUtils createFolderAtPath:self.path];
        
        self.gpxLogger = [[GpxLogger alloc] initWithFile:[self.path stringByAppendingPathComponent:@"sequence.gpx"]];
        
        
    }
    return self;
}

- (NSArray*)listImages
{
    // TODO
    
    MAPUser* author = [MAPLoginManager currentUser];
    
    NSMutableArray* images = [[NSMutableArray alloc] init];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    
    for (NSString* path in contents)
    {
        MAPImage* image = [[MAPImage alloc] init];
        image.imagePath = path;
        image.captureDate = [MAPUtils dateFromFilePath:path];
        image.author = author;
        image.location = nil;
        [images addObject:image];
    }
    
    return images;
}

- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date bearing:(NSNumber*)bearing location:(MAPLocation*)location
{
    // TODO
    
    if (location)
    {
        [self.gpxLogger add:location];
    }
}

- (void)addImageWithPath:(NSString*)imagePath date:(NSDate*)date bearing:(NSNumber*)bearing location:(MAPLocation*)location
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
    {
        NSData* data = [NSData dataWithContentsOfFile:imagePath];
        
        if (data)
        {
            [self addImageWithData:data date:date bearing:bearing location:location];
        }
    }
}

- (void)addLocation:(MAPLocation*)location date:(NSDate*)date
{
    // TODO
    
    if (location)
    {
        [self.gpxLogger add:location];
    }
}

- (void)addGpx:(NSString*)path
{
    // TODO
}

@end
