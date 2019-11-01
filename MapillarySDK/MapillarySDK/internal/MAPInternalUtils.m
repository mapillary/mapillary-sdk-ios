//
//  Utils.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPInternalUtils.h"
#include <sys/xattr.h>
#import "BOSImageResizeOperation.h"
#import <NSHash/NSString+NSHash.h>
#import "MAPDefines.h"
#import <sys/utsname.h>

@implementation MAPInternalUtils

+ (NSDateFormatter*)defaultDateFormatter
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss_SSS";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    dateFormatter.AMSymbol = @"";
    dateFormatter.PMSymbol = @"";
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    return dateFormatter;
}

+ (NSString *)getTimeString:(NSDate*)date
{
    NSDateFormatter* dateFormatter = [self defaultDateFormatter];
    
    if (date == nil)
    {
        date = [NSDate date];
    }
    
    NSString* dateString = [[dateFormatter stringFromDate:date] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return dateString;
}

+ (NSString *)documentsDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    
    return documentsDirectory;
}

+ (NSString *)basePath
{
    return [NSString stringWithFormat:@"%@/%@", [self documentsDirectory], @"mapillary"];
}

+ (NSString *)sequenceDirectory
{
    return [NSString stringWithFormat:@"%@/%@", [self basePath], @"sequences"];
}

+ (BOOL)createFolderAtPath:(NSString *)path
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:path])
    {
        BOOL success = [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        
        if (success)
        {
            [self addSkipBackupAttributeToItemAtPath:path];
        }
        
        return success;
    }
    
    return NO;
}

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString
{
    NSURL* fileURL = [NSURL fileURLWithPath:filePathString];
    
    const char* filePath = [fileURL.path fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

+ (NSDate*)dateFromFilePath:(NSString*)filePath
{
    NSString* fileName = [filePath lastPathComponent];
    NSString* strippedFileName = [fileName stringByDeletingPathExtension];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss_SSS";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    dateFormatter.AMSymbol = @"";
    dateFormatter.PMSymbol = @"";
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    return [dateFormatter dateFromString:strippedFileName];
}

+ (NSString*)appVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

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

+ (BOOL)usingStaging
{
    NSString* staging = NSBundle.mainBundle.infoDictionary[@"STAGING"];
    if ((staging && staging.intValue == 1) || [NSUserDefaults.standardUserDefaults integerForKey:kMAPSettingStaging] == 1)
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - Internal

+ (double)calculateFactorFromDates:(NSDate*)date date1:(NSDate*)date1 date2:(NSDate*)date2
{
    if (date1 == nil)
    {
        return 1.0;
    }
    
    if (date2 == nil)
    {
        return 0.0;
    }
    
    if ([date1 isEqualToDate:date2])
    {
        return 0.0;
    }
    
    return fabs([date1 timeIntervalSinceDate:date]/[date1 timeIntervalSinceDate:date2]);
}

+ (CLLocationCoordinate2D)interpolateCoords:(CLLocationCoordinate2D)location1 location2:(CLLocationCoordinate2D)location2 factor:(double)factor
{
    // == 0
    if (fabs(factor) < DBL_EPSILON)
    {
        return location1;
    }
    
    // == 1
    if (fabs(factor-1) < DBL_EPSILON)
    {
        return location2;
    }
    
    return CLLocationCoordinate2DMake((1-factor)*location1.latitude +factor*location2.latitude,
                                      (1-factor)*location1.longitude+factor*location2.longitude);
}

+ (NSNumber*)calculateHeadingFromCoordA:(CLLocationCoordinate2D)A B:(CLLocationCoordinate2D)B
{
    double lat1 = A.latitude;
    double lon1 = A.longitude;
    double lat2 = B.latitude;
    double lon2 = B.longitude;
    
    // From http://www.movable-type.co.uk/scripts/latlong.html
    double phi1 = lat1*M_PI/180.0;
    double phi2 = lat2*M_PI/180.0;
    double d1 = (lon2-lon1)*M_PI/180.0;
    double y = sin(d1) * cos(phi2);
    double x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(d1);
    double heading = atan2(y, x)*180.0/M_PI;
    
    heading = (heading < 360) ? heading + 360 : heading; // 0 - 360
    heading = (heading > 360) ? heading - 360 : heading; // 0 - 360
    
    return [NSNumber numberWithDouble:heading];
}

+ (MAPLocation*)locationBetweenLocationA:(MAPLocation*)locationA andLocationB:(MAPLocation*)locationB forDate:(NSDate*)date
{
    if (locationA == nil || locationB == nil)
    {
        return nil;
    }
    
    MAPLocation* result = [locationA copy];
    double factor;
    
    if (date == nil)
    {
        date = [NSDate dateWithTimeIntervalSince1970:AVG(locationA.timestamp.timeIntervalSince1970, locationB.timestamp.timeIntervalSince1970)];
        factor = 0.5;
    }
    else
    {
        factor = [MAPInternalUtils calculateFactorFromDates:date date1:locationA.timestamp date2:locationB.timestamp];
    }
    
    CLLocationCoordinate2D coordinate = [MAPInternalUtils interpolateCoords:locationA.location.coordinate location2:locationB.location.coordinate factor:factor];
    
    result.timestamp = date;
    
    // TODO use factor
    result.location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                    altitude:AVG(locationA.location.altitude,           locationB.location.altitude)
                                          horizontalAccuracy:AVG(locationA.location.horizontalAccuracy, locationB.location.horizontalAccuracy)
                                            verticalAccuracy:AVG(locationA.location.verticalAccuracy,   locationB.location.verticalAccuracy)
                                                   timestamp:date];
    
    // TODO use factor
    if (locationA.trueHeading && locationB.trueHeading && locationA.magneticHeading && locationB.magneticHeading)
    {
        result.trueHeading = [NSNumber numberWithDouble:AVG(locationA.trueHeading.doubleValue, locationB.trueHeading.doubleValue)];
        result.magneticHeading = [NSNumber numberWithDouble:AVG(locationA.magneticHeading.doubleValue, locationB.magneticHeading.doubleValue)];
    }
    else
    {
        result.magneticHeading = [self calculateHeadingFromCoordA:locationA.location.coordinate B:locationB.location.coordinate];
        result.trueHeading = result.magneticHeading;
        result.headingAccuracy = @0;
    }
    
    return result;
}

+ (void)createThumbnailForImage:(UIImage*)sourceImage atPath:(NSString*)path withSize:(CGSize)size
{
    BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:sourceImage];
    [op resizeToFitWithinSize:size];
    op.JPEGcompressionQuality = 0.5;
    [op writeResultToPath:path];
    [op start];
}

+ (NSString*)getSHA256HashFromString:(NSString*)string
{
    return [[string lowercaseString] SHA256];
}

@end
