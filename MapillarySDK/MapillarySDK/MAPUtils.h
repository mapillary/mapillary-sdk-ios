//
//  Utils.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPUtils : NSObject

+ (NSString *)getTimeString:(NSDate*)date;

+ (NSString *)documentsDirectory;
+ (NSString *)basePath;
+ (NSString *)sequenceDirectory;

+ (BOOL)createSubfolderAtPath:(NSString *)path folder:(NSString *)folder;
+ (BOOL)createFolderAtPath:(NSString *)path;
+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString;

+ (NSDate*)dateFromFilePath:(NSString*)filePath;

+ (NSString*)appVersion;

@end
