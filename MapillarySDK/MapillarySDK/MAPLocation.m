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
    
    if (fabs(self.latitude.doubleValue - aLocation.latitude.doubleValue) < CLCOORDINATE_EPSILON && fabs(self.longitude.doubleValue - aLocation.longitude.doubleValue) < CLCOORDINATE_EPSILON)
    {
        return YES;
    }
    
    return NO;
}
    
- (NSString*)description
{
    return [NSString stringWithFormat: @"Date: %@ Latitude: %f Longitude: %f", self.dateString, self.latitude.doubleValue, self.latitude.doubleValue];
}

@end
