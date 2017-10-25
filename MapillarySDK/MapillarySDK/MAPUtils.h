//
//  MAPUtils.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-10-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPLocation.h"

#define AVG(A, B) ((A+B)/2.0)

@interface MAPUtils : NSObject

+ (MAPLocation*)locationBetweenLocationA:(MAPLocation*)locationA andLocationB:(MAPLocation*)locationB forDate:(NSDate*)date;

@end
