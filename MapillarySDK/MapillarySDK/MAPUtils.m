//
//  Utils.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUtils.h"
#include <sys/xattr.h>

@implementation MAPUtils

+ (NSString *)getTimeString
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    //dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss_SSS";
    dateFormatter.AMSymbol = @"";
    dateFormatter.PMSymbol = @"";
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    NSString* dateString = [[dateFormatter stringFromDate:[NSDate date]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
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


+ (BOOL)createSubfolderAtPath:(NSString *)path folder:(NSString *)folder
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *newFolderPath = [path stringByAppendingPathComponent:folder];
    
    if (![fm fileExistsAtPath:newFolderPath])
    {
        NSLog(@"Creating %@", newFolderPath);
        BOOL success = [fm createDirectoryAtPath:newFolderPath withIntermediateDirectories:NO attributes:nil error:nil];
        
        if (success)
        {
            [self addSkipBackupAttributeToItemAtPath:newFolderPath];
        }
        
        return success;
    }
    
    return NO;
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
    dateFormatter.AMSymbol = @"";
    dateFormatter.PMSymbol = @"";
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    return [dateFormatter dateFromString:strippedFileName];
}

+ (NSString*)appVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

@end
