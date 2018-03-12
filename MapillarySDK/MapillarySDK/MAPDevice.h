//
//  MAPDevice.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-30.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPDevice : NSObject

@property NSString* make;
@property NSString* model;
@property NSString* UUID;

- (id)initWithMake:(NSString*)make andModel:(NSString*)model;
+ (id)thisDevice;

@end
