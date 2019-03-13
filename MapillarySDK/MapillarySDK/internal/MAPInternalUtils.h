//
//  Utils.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MAPLocation.h"

#define AVG(A, B) ((A+B)/2.0)

@interface MAPInternalUtils : NSObject

+ (NSString *)getTimeString:(NSDate*)date;

+ (NSString *)documentsDirectory;
+ (NSString *)basePath;
+ (NSString *)sequenceDirectory;

+ (BOOL)createFolderAtPath:(NSString*)path;
+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString*)filePathString;

+ (NSDate*)dateFromFilePath:(NSString*)filePath;

+ (NSString*)appVersion;

+ (double)calculateFactorFromDates:(NSDate*)date date1:(NSDate*)date1 date2:(NSDate*)date2;
+ (CLLocationCoordinate2D)interpolateCoords:(CLLocationCoordinate2D)location1 location2:(CLLocationCoordinate2D)location2 factor:(double)factor;
+ (NSNumber*)calculateHeadingFromCoordA:(CLLocationCoordinate2D)A B:(CLLocationCoordinate2D)B;

+ (NSDateFormatter*)defaultDateFormatter;

+ (MAPLocation*)locationBetweenLocationA:(MAPLocation*)locationA andLocationB:(MAPLocation*)locationB forDate:(NSDate*)date;

+ (void)createThumbnailForImage:(UIImage*)sourceImage atPath:(NSString*)path withSize:(CGSize)size;

+ (NSString*)getSHA256HashFromString:(NSString*)string;

+ (BOOL)usingStaging;

@end
