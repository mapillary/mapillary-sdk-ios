//
//  MAPDataManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-07-03.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MAPCoordinate+CoreDataClass.h"
#import <CoreLocation/CoreLocation.h>
#import "MAPLocation.h"
#import "MAPSequence.h"
#import "MAPUploadSession+CoreDataClass.h"

@interface MAPDataManager : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;

+ (MAPDataManager*)sharedManager;

- (void)saveChanges;

#pragma mark - Coordinates
- (void)addLocation:(MAPLocation*)location sequence:(MAPSequence*)sequence;
- (void)getAllLocationsLimitedToDevice:(MAPDevice*)inputDevice result:(void(^)(NSArray* locations, MAPDevice* device, NSString* organizationKey, bool isPrivate))result;
- (void)getLocationsFrom:(NSDate*)from to:(NSDate*)to limitedToDevice:(MAPDevice*)inputDevice result:(void(^)(NSArray* locations, MAPDevice* device, NSString* organizationKey, bool isPrivate))result;
- (void)deleteCoordinatesOlderThan:(NSDate*)date;

#pragma mark - Images
- (void)setImageAsProcessed:(MAPImage*)image;
- (void)removeImageInformation:(MAPImage*)image;
- (BOOL)isImageProcessed:(MAPImage*)image;
- (NSDictionary*)getProcessedImages;
- (void)deleteImagesOlderThan:(NSDate*)date;

#pragma mark - Upload sessions
- (void)addUploadSessionKey:(NSString*)uploadSessionKey uploadFields:(NSDictionary*)uploadFields uploadKeyPrefix:(NSString*)uploadKeyPrefix uploadUrl:(NSURL*)uploadUrl forSequence:(NSString*)sequenceKey;
- (void)removeUploadSession:(NSString*)uploadSessionKey;
- (void)removeUploadSessionForSequenceKey:(NSString*)sequenceKey;
- (NSArray*)getUploadSessions;
- (MAPUploadSession*)getUploadSessionForSequenceKey:(NSString*)sequenceKey;
- (MAPUploadSession*)getUploadSessionForSessionKey:(NSString*)uploadSessionKey;

@end
