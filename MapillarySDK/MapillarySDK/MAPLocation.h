//
//  MAPLocation.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface MAPLocation : NSObject <NSCopying>

@property CLLocation* location;
@property CLHeading* heading;
@property NSDate* timestamp;
@property CMDeviceMotion* deviceMotion;

- (BOOL)isEqualToLocation:(MAPLocation*)aLocation;
- (NSString*)timeString;

@end
