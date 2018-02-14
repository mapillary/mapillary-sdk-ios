//
//  MAPSequence+Private.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-01-25.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPSequence+Private.h"
#import "MAPDefines.h"

@implementation MAPSequence(Private)

- (void)lock
{
    NSString* path = [self.path stringByAppendingPathComponent:@"lock"];
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
}

- (void)unlock
{
    NSString* path = [self.path stringByAppendingPathComponent:@"lock"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}
- (NSMutableDictionary*)meta
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    dict[kMAPDirection] = [NSNumber numberWithDouble:self.directionOffset];
    
     dict[kMAPSettingsTokenValid] = [NSNumber numberWithDouble:self.directionOffset];
    dict[kMAPSettingsUserKey] = [NSNumber numberWithDouble:self.directionOffset];
    dict[kMAPOrganizationKey] = [NSNumber numberWithDouble:self.directionOffset];
    dict[kMAPPrivate] = [NSNumber numberWithDouble:self.directionOffset];
    dict[kMAPVersionString] = [NSNumber numberWithDouble:self.directionOffset];
    dict[kMAPLocalTimeZone] = [NSNumber numberWithDouble:self.directionOffset];
    
    return dict;
}

@end
