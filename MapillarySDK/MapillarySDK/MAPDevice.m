//
//  MAPDevice.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-30.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPDevice.h"
#import <SDVersion/SDVersion.h>
#import <UIKit/UIKit.h>

@implementation MAPDevice

- (id)initWithMake:(NSString*)make andModel:(NSString*)model andUUID:(NSString*)uuid isExternal:(BOOL)isExternal
{
    self = [super init];
    if (self)
    {
        self.make = make;
        self.model = model;
        self.UUID = uuid;
        self.isExternal = isExternal;
    }
    return self;
}

+ (id)thisDevice
{
    MAPDevice* current = [[MAPDevice alloc] initWithMake:@"Apple" andModel:[SDVersion deviceNameString] andUUID:[[[UIDevice currentDevice] identifierForVendor] UUIDString] isExternal:NO];
    
    return current;
}

@end
