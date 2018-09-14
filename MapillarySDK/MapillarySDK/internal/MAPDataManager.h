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

@interface MAPDataManager : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;

+ (MAPDataManager*)sharedManager;

- (void)saveChanges;

#pragma mark - Coordinates
- (void)addLocation:(MAPLocation*)location sequence:(MAPSequence*)sequence;
- (void)getAllLocationsLimitedToDevice:(MAPDevice*)inputDevice result:(void(^)(NSArray* locations, MAPDevice* device, NSString* organizationKey, bool isPrivate))result;
- (void)getLocationsFrom:(NSDate*)from to:(NSDate*)to limitedToDevice:(MAPDevice*)inputDevice result:(void(^)(NSArray* locations, MAPDevice* device, NSString* organizationKey, bool isPrivate))result;
- (void)deleteCoordinatesOlderThan:(NSDate*)date;


@end
