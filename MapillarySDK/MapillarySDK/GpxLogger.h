//
//  GpxLogger.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-03-21.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GpxLogger : NSObject

- (id)initWithFile:(NSString*)path;
- (void)add:(CLLocation*)location;

+ (void)test;

@end