//
//  Utils.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (NSString *)getTimeString;

+ (NSString *)documentsDirectory;
+ (NSString *)basePath;
+ (NSString *)sequenceDirectory;

+ (BOOL)createSubfolderAtPath:(NSString *)path folder:(NSString *)folder;
+ (BOOL)createFolderAtPath:(NSString *)path;
+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString;

@end
