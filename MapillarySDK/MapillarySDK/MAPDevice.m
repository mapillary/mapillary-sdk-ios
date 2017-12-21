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

+ (id)currentDevice
{
    MAPDevice* current = [[MAPDevice alloc] init];
    current.make = @"Apple";
    current.model = [SDVersion deviceNameString];
    current.UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    return current;
}

@end
