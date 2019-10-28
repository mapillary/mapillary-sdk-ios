//
//  MAPUtils.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-10-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUtils.h"
#import "MAPFileManager.h"
#import <sys/utsname.h>

@implementation MAPUtils

+ (NSString*)deviceName
{
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode)
    {
        // From https://gist.github.com/adamawolf/3048717
        
        deviceNamesByCode = @{@"i386"       : @"Simulator",
                              @"x86_64"     : @"Simulator",
                              
                              @"iPod1,1"    : @"iPod Touch",
                              @"iPod2,1"    : @"iPod Touch",
                              @"iPod3,1"    : @"iPod Touch",
                              @"iPod4,1"    : @"iPod Touch",
                              @"iPod5,1"    : @"iPod Touch",
                              @"iPod7,1"    : @"iPod Touch",
                              
                              @"iPhone1,1"  : @"iPhone 2G",
                              @"iPhone1,2"  : @"iPhone 3G",
                              @"iPhone2,1"  : @"iPhone 3GS",
                              @"iPhone3,1"  : @"iPhone 4",
                              @"iPhone3,2"  : @"iPhone 4",
                              @"iPhone3,3"  : @"iPhone 4",
                              @"iPhone4,1"  : @"iPhone 4S",
                              @"iPhone5,1"  : @"iPhone 5",
                              @"iPhone5,2"  : @"iPhone 5",
                              @"iPhone5,3"  : @"iPhone 5c",
                              @"iPhone5,4"  : @"iPhone 5c",
                              @"iPhone6,1"  : @"iPhone 5s",
                              @"iPhone6,2"  : @"iPhone 5s",
                              @"iPhone7,1"  : @"iPhone 6 Plus",
                              @"iPhone7,2"  : @"iPhone 6",
                              @"iPhone8,1"  : @"iPhone 6s",
                              @"iPhone8,2"  : @"iPhone 6 Plus",
                              @"iPhone8,3"  : @"Phone SE",
                              @"iPhone8,4"  : @"iPhone SE",
                              @"iPhone9,1"  : @"iPhone 7",
                              @"iPhone9,2"  : @"iPhone 7 Plus",
                              @"iPhone9,3"  : @"iPhone 7",
                              @"iPhone9,4"  : @"iPhone 7 Plus",
                              @"iPhone10,1" : @"iPhone 8",
                              @"iPhone10,2" : @"iPhone 8 Plus",
                              @"iPhone10,3" : @"iPhone X",
                              @"iPhone10,4" : @"iPhone 8",
                              @"iPhone10,5" : @"iPhone 8 Plus",
                              @"iPhone10,6" : @"iPhone X",
                              @"iPhone11,2" : @"iPhone XS",
                              @"iPhone11,4" : @"iPhone XS Max",
                              @"iPhone11,6" : @"iPhone XS Max",
                              @"iPhone11,8" : @"iPhone XR",
                              @"iPhone12,1" : @"iPhone 11",
                              @"iPhone12,3" : @"iPhone 11 Pro",
                              @"iPhone12,5" : @"iPhone 11 Pro Max",
                              
                              @"iPad1,1"    : @"iPad",
                              @"iPad1,2"    : @"iPad",
                              @"iPad2,1"    : @"iPad 2",
                              @"iPad2,2"    : @"iPad 2",
                              @"iPad2,3"    : @"iPad 2",
                              @"iPad2,4"    : @"iPad 2",
                              @"iPad2,5"    : @"iPad Mini",
                              @"iPad2,6"    : @"iPad Mini",
                              @"iPad2,7"    : @"iPad Mini",
                              @"iPad3,1"    : @"iPad 3",
                              @"iPad3,2"    : @"iPad 3",
                              @"iPad3,3"    : @"iPad 3",
                              @"iPad3,4"    : @"iPad 4",
                              @"iPad3,5"    : @"iPad 4",
                              @"iPad3,6"    : @"iPad 4",
                              @"iPad4,1"    : @"iPad Air",
                              @"iPad4,2"    : @"iPad Air",
                              @"iPad4,3"    : @"iPad Air",
                              @"iPad4,4"    : @"iPad Mini 2",
                              @"iPad4,5"    : @"iPad Mini 2",
                              @"iPad4,6"    : @"iPad Mini 2",
                              @"iPad4,7"    : @"iPad Mini 3",
                              @"iPad4,8"    : @"iPad Mini 3",
                              @"iPad4,9"    : @"iPad Mini 3",
                              @"iPad5,1"    : @"iPad Mini 4",
                              @"iPad5,2"    : @"iPad Mini 4",
                              @"iPad5,3"    : @"iPad Air 2",
                              @"iPad5,4"    : @"iPad Air 2",
                              @"iPad6,3"    : @"iPad Pro",
                              @"iPad6,4"    : @"iPad Pro",
                              @"iPad6,7"    : @"iPad Pro",
                              @"iPad6,8"    : @"iPad Pro",
                              @"iPad6,11"   : @"iPad",
                              @"iPad6,12"   : @"iPad",
                              @"iPad7,1"    : @"iPad Pro",
                              @"iPad7,2"    : @"iPad Pro",
                              @"iPad7,3"    : @"iPad Pro",
                              @"iPad7,4"    : @"iPad Pro",
                              @"iPad7,5"    : @"iPad",
                              @"iPad7,6"    : @"iPad",
                              @"iPad8,1"    : @"iPad Pro)",
                              @"iPad8,2"    : @"iPad Pro)",
                              @"iPad8,3"    : @"iPad Pro)",
                              @"iPad8,4"    : @"iPad Pro)",
                              @"iPad8,5"    : @"iPad Pro)",
                              @"iPad8,6"    : @"iPad Pro)",
                              @"iPad8,7"    : @"iPad Pro)",
                              @"iPad8,8"    : @"iPad Pro)",
                              @"iPad11,1"   : @"iPad Mini 5",
                              @"iPad11,2"   : @"iPad Mini 5",
                              @"iPad11,3"   : @"iPad Air 3",
                              @"iPad11,4"   : @"iPad Air 3"
                              
                              };
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    // Not found on database. At least guess main device type from string contents:
    if (!deviceName)
    {
        if ([code rangeOfString:@"iPod"].location != NSNotFound)
        {
            deviceName = @"iPod Touch";
        }
        else if ([code rangeOfString:@"iPad"].location != NSNotFound)
        {
            deviceName = @"iPad";
        }
        else if ([code rangeOfString:@"iPhone"].location != NSNotFound)
        {
            deviceName = @"iPhone";
        }
    }
    
    return deviceName;
}

@end
