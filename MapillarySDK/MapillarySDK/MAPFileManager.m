//
//  MAPFileManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPFileManager.h"
#import "MAPInternalUtils.h"
#import "MAPDataManager.h"
#import "MAPApiManager.h"

@implementation MAPFileManager

+ (NSArray*)getSequences:(BOOL)parseGpx;
{
    NSMutableArray* sequences = [[NSMutableArray alloc] init];
    NSString* sequenceDirectory = [MAPInternalUtils sequenceDirectory];

    NSError* error = nil;
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sequenceDirectory error:&error];
    
    if (!error)
    {
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"";
        
        for (NSString* file in contents)
        {
            MAPSequence* sequence = [[MAPSequence alloc] initWithPath:[NSString stringWithFormat:@"%@/%@", sequenceDirectory, file] parseGpx:parseGpx];
            [sequences addObject:sequence];
        }
        
        [sequences sortUsingComparator:^NSComparisonResult(MAPSequence* obj1, MAPSequence* obj2) {
            
            return [obj2.sequenceDate compare:obj1.sequenceDate];
            
        }];
    }

    return sequences;
}

+ (void)getSequencesAsync:(BOOL)parseGpx done:(void(^)(NSArray* sequences))result
{
    if (result == nil)
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray* sequences = [self getSequences:parseGpx];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            result(sequences);
            
        });
        
    });
}

+ (void)deleteSequence:(MAPSequence*)sequence
{
    // Delete upload session
    MAPUploadSession* uploadSession = [[MAPDataManager sharedManager] getUploadSessionForSequenceKey:sequence.sequenceKey];
    
    if (uploadSession != nil)
    {
        NSLog(@"CLOSING SESSION");
        [MAPApiManager endUploadSession:uploadSession.uploadSessionKey done:^(BOOL success) {
            
        }];
    }
    
    // Delete folder
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:sequence.path error:nil];
}

@end
