//
//  MAPCoordinate+CoreDataProperties.m
//  
//
//  Created by Anders Mårtensson on 2018-09-03.
//
//

#import "MAPCoordinate+CoreDataProperties.h"

@implementation MAPCoordinate (CoreDataProperties)

+ (NSFetchRequest<MAPCoordinate *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MAPCoordinate"];
}

@dynamic altitude;
@dynamic angle;
@dynamic deviceMake;
@dynamic deviceModel;
@dynamic deviceUUID;
@dynamic deviceMotionX;
@dynamic deviceMotionY;
@dynamic deviceMotionZ;
@dynamic devicePitch;
@dynamic deviceRoll;
@dynamic deviceYaw;
@dynamic headingAccuracy;
@dynamic isPrivate;
@dynamic latitude;
@dynamic longitude;
@dynamic magneticHeading;
@dynamic organizationKey;
@dynamic speed;
@dynamic timestamp;
@dynamic trueHeading;

@end
