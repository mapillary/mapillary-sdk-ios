//
//  MAPLocation.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPLocation : NSObject

@property NSNumber* latitude;
@property NSNumber* longitude;
@property NSNumber* originalBearing;
@property NSNumber* calculatedBearing;
@property NSNumber* elevation;
@property NSDate* date;
@property NSString* dateString;
    
- (BOOL)isEqualToLocation:(MAPLocation*)aLocation;

@end
