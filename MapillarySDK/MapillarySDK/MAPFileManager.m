//
//  MAPFileManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPFileManager.h"
#import "MAPInternalUtils.h"
#import "MAPGpxParser.h"

@implementation MAPFileManager

+ (void)listSequences:(void(^)(NSArray* sequences))result
{
    if (result == nil)
    {
        return;
    }
    
    NSMutableArray* sequences = [[NSMutableArray alloc] init];
    NSString* sequenceDirectory = [MAPInternalUtils sequenceDirectory];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sequenceDirectory error:nil];
    
    for (NSString* path in contents)
    {
        NSString* gpxPath = [NSString stringWithFormat:@"%@/%@/sequence.gpx", sequenceDirectory, path];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:gpxPath])
        {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:gpxPath];
            
            [parser quickParse:^(NSDictionary *result) {
                
                NSNumber* directionOffset = result[@"directionOffset"];
                NSNumber* timeOffset = result[@"timeOffset"];
                
                MAPDevice* device = [[MAPDevice alloc] init];
                device.make = result[@"deviceMake"];
                device.model = result[@"deviceModel"];
                device.UUID = result[@"deviceUUID"];
                
                MAPSequence* sequence = [[MAPSequence alloc] init];
                sequence.path = [NSString stringWithFormat:@"%@/%@", sequenceDirectory, path];
                sequence.sequenceKey = result[@"sequenceKey"];
                sequence.sequenceDate = result[@"sequenceDate"];
                sequence.directionOffset = directionOffset.doubleValue;
                sequence.timeOffset = timeOffset.doubleValue;
                sequence.project = result[@"project"];
                sequence.device = device;
                
                [sequences addObject:sequence];
                
                dispatch_semaphore_signal(semaphore);
                
            }];
            
            // Wait here intil done
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    }
    
    result(sequences);
}

+ (void)deleteSequence:(MAPSequence*)sequence
{
    NSFileManager* fm = [NSFileManager defaultManager];

    // Delete folder
    [fm removeItemAtPath:sequence.path error:nil];
}

+ (void)deleteImage:(MAPImage*)image
{
    [[NSFileManager defaultManager] removeItemAtPath:image.imagePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:image.thumbPath error:nil];
}

@end
