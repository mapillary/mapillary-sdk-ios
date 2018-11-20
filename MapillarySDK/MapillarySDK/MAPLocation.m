//
//  MAPLocation.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPLocation.h"

#define CLCOORDINATE_EPSILON 0.00000000001f

@implementation MAPLocation

- (id)init
{
    self = [super init];
    if (self)
    {
        self.location = nil;
        self.trueHeading = 0;
        self.magneticHeading = 0;
        self.headingAccuracy = 0;
        self.timestamp = [NSDate date];
        self.deviceMotionX = 0;
        self.deviceMotionY = 0;
        self.deviceMotionZ = 0;
        self.devicePitch = 0;
        self.deviceRoll = 0;
        self.deviceYaw = 0;
    }
    return self;
}
    
- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }

    if (!other || ![other isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return [self isEqualToLocation:other];
}
    
- (BOOL)isEqualToLocation:(MAPLocation*)aLocation
{
    if (self == aLocation)
    {
        return YES;
    }
    
    if (fabs(self.location.coordinate.latitude - aLocation.location.coordinate.latitude) < CLCOORDINATE_EPSILON && fabs(self.location.coordinate.longitude - aLocation.location.coordinate.longitude) < CLCOORDINATE_EPSILON)
    {
        return YES;
    }
    
    return NO;
}
    
- (NSString*)description
{
    return [NSString stringWithFormat: @"Date: %@ Latitude: %f Longitude: %f", [self timeString], self.location.coordinate.latitude, self.location.coordinate.longitude];
}

- (NSString*)timeString
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    return [dateFormatter stringFromDate:self.timestamp];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy)
    {
        [copy setLocation:self.location.copy];
        [copy setTrueHeading:self.trueHeading];
        [copy setMagneticHeading:self.magneticHeading];
        [copy setHeadingAccuracy:self.headingAccuracy];
        [copy setTimestamp:self.timestamp.copy];
        [copy setDeviceMotionX:self.deviceMotionX];
        [copy setDeviceMotionY:self.deviceMotionY];
        [copy setDeviceMotionZ:self.deviceMotionZ];
        [copy setDevicePitch:self.devicePitch];
        [copy setDeviceRoll:self.deviceRoll];
        [copy setDeviceYaw:self.deviceYaw];
    }
    
    return copy;
}

@end
