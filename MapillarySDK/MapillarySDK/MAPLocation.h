//
//  MAPLocation.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MAPLocation : NSObject

@property CLLocation* location;
@property CLHeading* heading;
@property NSDate* timestamp;

- (BOOL)isEqualToLocation:(MAPLocation*)aLocation;
- (NSString*)timeString;

@end
