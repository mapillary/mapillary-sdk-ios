//
//  MAPCoordinate+CoreDataProperties.h
//  
//
//  Created by Anders Mårtensson on 2018-09-03.
//
//

#import "MAPCoordinate+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MAPCoordinate (CoreDataProperties)

+ (NSFetchRequest<MAPCoordinate *> *)fetchRequest;

@property (nonatomic) double altitude;
@property (nonatomic) double angle;
@property (nonatomic) NSString* deviceMake;
@property (nonatomic) NSString* deviceModel;
@property (nonatomic) NSString* deviceUUID;
@property (nonatomic) double deviceMotionX;
@property (nonatomic) double deviceMotionY;
@property (nonatomic) double deviceMotionZ;
@property (nonatomic) double devicePitch;
@property (nonatomic) double deviceRoll;
@property (nonatomic) double deviceYaw;
@property (nonatomic) double headingAccuracy;
@property (nonatomic) BOOL isPrivate;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double magneticHeading;
@property (nullable, nonatomic, copy) NSString *organizationKey;
@property (nonatomic) double speed;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nonatomic) double trueHeading;

@end

NS_ASSUME_NONNULL_END
