//
//  Utils.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MAPInternalUtils : NSObject

+ (NSString *)getTimeString:(NSDate*)date;

+ (NSString *)documentsDirectory;
+ (NSString *)basePath;
+ (NSString *)sequenceDirectory;

+ (BOOL)createSubfolderAtPath:(NSString*)path folder:(NSString*)folder;
+ (BOOL)createFolderAtPath:(NSString*)path;
+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString*)filePathString;

+ (NSDate*)dateFromFilePath:(NSString*)filePath;

+ (NSString*)appVersion;

+ (float)calculateFactorFromDates:(NSDate*)date date1:(NSDate*)date1 date2:(NSDate*)date2;
+ (CLLocationCoordinate2D)interpolateCoords:(CLLocationCoordinate2D)location1 location2:(CLLocationCoordinate2D)location2 factor:(float)factor;
+ (double)calculateHeadingFromCoordA:(CLLocationCoordinate2D)A B:(CLLocationCoordinate2D)B;

+ (NSDateFormatter*)defaultDateFormatter;

@end
