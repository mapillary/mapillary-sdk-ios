//
//  MAPDevice.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-30.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The `MAPDevice` class encapsulates the information about a device used for
 capture.
 */
@interface MAPDevice : NSObject

///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 The make of the device, i.e. "Apple".
 */
@property NSString* make;

/**
 The model of the device, i.e. "iPhone 8".
 */
@property NSString* model;

/**
 A unique id of the device.
 */
@property NSString* UUID;

///-----------------------------------------------------------------------------
/// @name Initializers
///-----------------------------------------------------------------------------

/**
 Creates a device object.
 
 @param make The make of the device.
 @param model The model of the device.
 */
- (id)initWithMake:(NSString*)make andModel:(NSString*)model;

/**
 Returns the device the app is running on.
 */
+ (id)thisDevice;

@end
