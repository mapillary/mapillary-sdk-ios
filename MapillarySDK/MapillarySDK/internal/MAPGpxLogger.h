//
//  MAPGpxLogger.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-03-21.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "MAPLocation.h"
#import "MAPSequence.h"

@interface MAPGpxLogger : NSObject

@property (nonatomic) BOOL busy;

- (id)initWithFile:(NSString*)path andSequence:(MAPSequence*)sequence;
- (void)addLocation:(MAPLocation*)location;

@end
