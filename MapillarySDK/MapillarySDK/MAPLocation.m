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
    /*if (self == aLocation)
    {
        return YES;
    }
    
    if (fabs(self.location.coordinate.latitude - aLocation.coordinate.latitude) < CLCOORDINATE_EPSILON && fabs(self.coordinate.longitude - aLocation.coordinate.longitude) < CLCOORDINATE_EPSILON)
    {
        return YES;
    }
    
    return NO;*/
    
    return [self.location isEqual:aLocation.location];
}
    
- (NSString*)description
{
    return [NSString stringWithFormat: @"Date: %@ Latitude: %f Longitude: %f", [self timeString], self.location.coordinate.latitude, self.location.coordinate.latitude];
}

- (NSString*)timeString
{
    return nil; // TODO
}

@end
