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
    double dy = A.latitude - B.latitude;
    double dx = A.longitude - B.longitude;
    
    double heading = atan(dy/dx) * 180.0 / M_PI;
        
    heading = (heading <   0) ? heading + 360 : heading; // 0 - 360
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
