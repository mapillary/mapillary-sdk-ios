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

/**
 The `MAPLocation` class encapsulates the information about a location.
 */
@interface MAPLocation : NSObject <NSCopying>

///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 The actual `CLLocation` returned from a CLLocationManager.
 
 @see CLLocation
 @see CLLocationManager
 */
@property CLLocation* location;

/**
 The magnetic heading when this location was recorded.
 */
@property NSNumber* magneticHeading;

/**
 The true heading when this location was recorded.
 */
@property NSNumber* trueHeading;

/**
 The heading accuracy when this location was recorded.
 */
@property NSNumber* headingAccuracy;

/**
 The date when this location was recorded.
 */
@property NSDate* timestamp;

/**
 The device motion X value when this location was recorded. This value should be
 obtained from a `CMDeviceMotion` object returned by a `CMMotionManager`.
 
 @see CMMotionManager
 @see CMDeviceMotion
 */
@property NSNumber* deviceMotionX;

/**
 The device motion Y value when this location was recorded. This value should be
 obtained from a `CMDeviceMotion` object returned by a `CMMotionManager`.
 
 @see CMMotionManager
 @see CMDeviceMotion
 */
@property NSNumber* deviceMotionY;

/**
 The device motion Z value when this location was recorded. This value should be
 obtained from a `CMDeviceMotion` object returned by a `CMMotionManager`.
 
 @see CMMotionManager
 @see CMDeviceMotion
 */
@property NSNumber* deviceMotionZ;

/**
 The device's attitude - its orientation relative to a known frame of
 reference—at a point in time obtained from a `CMDeviceMotion` object returned
 by a `CMMotionManager`.
 
 @see CMMotionManager
 @see CMDeviceMotion
 */

/**
 The device motion X value when this location was recorded. This value should be
 obtained from a `CMDeviceMotion` object returned by a `CMMotionManager`.
 
 @see CMMotionManager
 @see CMDeviceMotion
 */
@property NSNumber* deviceRoll;

/**
 The device motion Y value when this location was recorded. This value should be
 obtained from a `CMDeviceMotion` object returned by a `CMMotionManager`.
 
 @see CMMotionManager
 @see CMDeviceMotion
 */
@property NSNumber* devicePitch;

/**
 The device motion Z value when this location was recorded. This value should be
 obtained from a `CMDeviceMotion` object returned by a `CMMotionManager`.
 
 @see CMMotionManager
 @see CMDeviceMotion
 */
@property NSNumber* deviceYaw;

///-----------------------------------------------------------------------------
/// @name Utility
///-----------------------------------------------------------------------------

/**
 Compares this location with another location to see if they are close enough
 to be considered the same.
 
 @param aLocation Another location object.
 @rwturn YES if the locations are in the same place, NO otherwise.
 */
- (BOOL)isEqualToLocation:(MAPLocation*)aLocation;

/**
 Returns the capture date as a string in the UTC format.
 
 @return The string representation of the capture date.
 */
- (NSString*)timeString;

@end
