//
//  MAPUtils.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-10-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUtils.h"
#import "MAPInternalUtils.h"

@implementation MAPUtils

+ (MAPLocation*)locationBetweenLocationA:(MAPLocation*)locationA andLocationB:(MAPLocation*)locationB forDate:(NSDate*)date
{
    if (locationA == nil || locationB == nil)
    {
        return nil;
    }
    
    MAPLocation* result = locationA;
    float factor;
    
    if (date == nil)
    {
        date = [NSDate dateWithTimeIntervalSince1970:AVG(locationA.timestamp.timeIntervalSince1970, locationB.timestamp.timeIntervalSince1970)];
        factor = 0.5;
    }
    else
    {
        factor = [MAPInternalUtils calculateFactorFromDates:date date1:locationA.timestamp date2:locationB.timestamp];
    }
    
    CLLocationCoordinate2D coordinate = [MAPInternalUtils interpolateCoords:locationA.location.coordinate location2:locationB.location.coordinate factor:factor];
    
    result.timestamp = date;
    result.location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                    altitude:AVG(locationA.location.altitude,           locationB.location.altitude)
                                          horizontalAccuracy:AVG(locationA.location.horizontalAccuracy, locationB.location.horizontalAccuracy)
                                            verticalAccuracy:AVG(locationA.location.verticalAccuracy,   locationB.location.verticalAccuracy)
                                                   timestamp:date];
    
    // TODO add more
    
    return result;
}

@end
