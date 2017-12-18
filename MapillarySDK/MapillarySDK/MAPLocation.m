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
        self.heading = nil;
        self.timestamp = nil;
        self.deviceMotion = nil;
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
    return [NSString stringWithFormat: @"Date: %@ Latitude: %f Longitude: %f", [self timeString], self.location.coordinate.latitude, self.location.coordinate.latitude];
}

- (NSString*)timeString
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    return [dateFormatter stringFromDate:self.timestamp];
}

#pragma mark - NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy)
    {
        [copy setLocation:self.location.copy];
        [copy setHeading:self.heading.copy];
        [copy setTimestamp:self.timestamp.copy];
        [copy setDeviceMotion:self.deviceMotion.copy];
    }
    
    return copy;
}



@end
