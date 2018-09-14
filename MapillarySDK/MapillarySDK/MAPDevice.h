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

/**
 Defines if the device is an external or an internal device. If the device is
 internal, a GPX file will be created during capture. If external, no GPX file
 is created during capture, instead the coordinates are saved in a database.
 */
@property BOOL isExternal;

///-----------------------------------------------------------------------------
/// @name Initializers
///-----------------------------------------------------------------------------

/**
 Creates a device object.
 
 @param make The make of the device.
 @param model The model of the device.
 @param uuid A unique identifier of the device.
 @param isExternal Defines if the device is external or not.
 */
- (id)initWithMake:(NSString*)make andModel:(NSString*)model
           andUUID:(NSString*)uuid isExternal:(BOOL)isExternal;

/**
 Returns the device the app is running on.
 */
+ (id)thisDevice;

@end
