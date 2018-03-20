//
//  MAPSequence+Private.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-01-25.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPSequence+Private.h"
#import "MAPDefines.h"
#import "MAPLoginManager.h"

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
    dict[kMAPSettingsTokenValid]    = @1;
    dict[kMAPSettingsUserKey]       = [[NSUserDefaults standardUserDefaults] objectForKey:MAPILLARY_CURRENT_USER_KEY];
    dict[kMAPLocalTimeZone]         = [NSString stringWithFormat:@"%@", [NSTimeZone systemTimeZone]];
    // dict[kMAPOrganizationKey]    = // TODO
    // dict[kMAPPrivate]            = // TODO
    dict[kMAPAppNameString]         = @"mapillary_ios";
    dict[kMAPDeviceMake]            = self.device.make;
    dict[kMAPDeviceModel]           = self.device.model;
    dict[kMAPCameraUUID]            = self.device.UUID;
    dict[kMAPSequenceUUID]          = self.sequenceKey;
    dict[kMAPSettingsProject]       = self.project;
        
    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString* bundle = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    dict[kMAPVersionString] = [NSString stringWithFormat:@"%@ (%@)", version, bundle];
    
    return dict;
}

@end
