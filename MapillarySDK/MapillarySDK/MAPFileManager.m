//
//  MAPFileManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPFileManager.h"
#import "MAPUtils.h"

@implementation MAPFileManager

+ (NSArray*)listSequences
{
    // TODO
    
    NSMutableArray* sequences = [[NSMutableArray alloc] init];
    NSString* sequenceDirectory = [MAPUtils sequenceDirectory];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sequenceDirectory error:nil];
    
    for (NSString* path in contents)
    {
        MAPSequence* sequence = [[MAPSequence alloc] init];
        sequence.path = path;
        sequence.sequenceDate = [NSDate date];
        sequence.directionOffset = 0;
        sequence.timeOffset = 0;
        [sequences addObject:sequence];
    }
    
    return sequences;
}

+ (void)deleteSequence:(MAPSequence*)sequence
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Delete meta
    // TODO
    
    // Delete folder
    [fm removeItemAtPath:sequence.path error:nil];
}

+ (void)deleteImage:(MAPImage*)image
{
    [[NSFileManager defaultManager] removeItemAtPath:image.imagePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:image.thumbPath error:nil];
}

@end
