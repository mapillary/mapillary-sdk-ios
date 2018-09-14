//
//  MAPSequence.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPLocation.h"
#import "MAPDevice.h"
#import "MAPImage.h"

/**
 The MAPSequence class describes a sequence. A sequence consists of images and
 locations. Internally, all data is stored in a compliant GPX file which works
 in other programs as well if you decide to export it.
 
 The location of an image is calculated using the date and time the image was
 captured and is interpolated between GPS points in the GPX file.
 processImage
 If you want to export the image and get all the EXIF data added, you need to
 process the image first using `-[MAPSequence processImage:]`.
 
 @see http://www.topografix.com/gpx.asp
 @see http://www.topografix.com/gpx/1/1/
 */
@interface MAPSequence : NSObject

///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 The direction offset in degrees. -1 means not set, 0 means straight forward,
 90 means 90 degress to the right etc. When the heading is calculated it uses
 this value to correct the heading.
 
 If the value is -1 the compass angle will be used.
 If the value is 0, the compass angle is ignored and instead the value is
 interpolated between two locations.
 If the value is >0, the compass angle is ignored and instead the value is
 interpolated between two locations and also adds this value.
 */
@property NSNumber* directionOffset;

/**
 The time offset in milliseconds.
 
 Default is nil. It means it is not set. +1 means the image date is increased
 by 1 ms when calculating the position of and image. -1 means the image date
 is decreased by 1 ms when calculating the position of and image.
 */
@property NSNumber* timeOffset;

/**
 The date the sequence was captured.
*/
@property NSDate* sequenceDate;

/**
 The path to the directory containing this sequence.
 */
@property NSString* path;

/**
 The path to the GPX file for this sequence. Can be nil.
 */
@property NSString* gpxPath;

/**
 The organization this sequence belongs to. Default is nil.
 */
@property NSString* organizationKey;

/**
 If the sequence is private or public. Only used if organizationKey is set.
 Default is NO.
 */
@property BOOL isPrivate;

/**
 The unique key of this sequence.
 */
@property NSString* sequenceKey;

/**
 The device used to capture this sequence.
 */
@property MAPDevice* device;

/**
 Number of images in this sequence.
 */
@property NSUInteger imageCount;

/**
 The size in bytes of the all the images in this sequence.
 */
@property NSUInteger sequenceSize;

/**
 The image orientation this sequence was captured in.
 */
@property NSNumber* imageOrientation;

/**
 The common identifier of this sequence for a rig. This is used to connect
 several separate sequences together.
 */
@property NSString* rigSequenceUUID;

/**
 The unique identifier of the rig used to capture this sequence.
 */
@property NSString* rigUUID;

///-----------------------------------------------------------------------------
/// @name Initializers
///-----------------------------------------------------------------------------

/**
 Creates a new sequence for a specific device with the current date.
 
 @param device A device.
 */
- (id)initWithDevice:(MAPDevice*)device;

/**
 Creates a new sequence for a specific device with a specific date.
 
 @param device A device.
 @param date The date of the sequence.
 */
- (id)initWithDevice:(MAPDevice*)device andDate:(NSDate*)date;

/**
 Creates and initilizes a sequence from an existing sequence.
 
 @param path The path to the directory containing the sequence.
 @param parseGpx If YES, the GPX file will be parsed and all properties will
                 be initialized. If NO, the GPX file will not be parsed and some
                 properties will not be initialized. Setting this parameter to
                 YES is much slower than NO.
 */
- (id)initWithPath:(NSString*)path parseGpx:(BOOL)parseGpx;

///-----------------------------------------------------------------------------
/// @name Adding images
///-----------------------------------------------------------------------------

/**
 Adds an image to the sequence.
 
 @param imageData The image data of an image.
 @param date The date the image was captured. If `nil` the current date is used.
 @param location The location the image was captured. Can be nil.
 */
- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date location:(MAPLocation*)location;

/**
 Adds an image to the sequence.
 
 @param imagePath The file path to the image on disk.
 @param date The date the image was captured. If `nil` the current date is used.
 @param location The location the image was captured. Can be nil.
 */
- (void)addImageWithPath:(NSString*)imagePath date:(NSDate*)date location:(MAPLocation*)location;

///-----------------------------------------------------------------------------
/// @name Deleting images
///-----------------------------------------------------------------------------

/**
 Deletes an image.
 
 @param image The image to delete.
 */
- (void)deleteImage:(MAPImage*)image;

/**
 Deletes all the images in this sequence.
 */
- (void)deleteAllImages;

///-----------------------------------------------------------------------------
/// @name Getting images
///-----------------------------------------------------------------------------

/**
 Gets the images in this sequence as an array of `MAPImage` objects.
 
 @return The images in this sequence.
 @see MAPImage
 */
- (NSArray*)getImages;

/**
 Gets the images in this sequence as an array of `MAPImage` objects.
 
 @param images The images in this sequence.
 @see MAPImage
 */
- (void)getImagesAsync:(void(^)(NSArray* images))images;

///-----------------------------------------------------------------------------
/// @name Adding locations
///-----------------------------------------------------------------------------

/**
 Adds a location to the sequence.
 
 @param location The location to add.
 @see MAPLocation
 */
- (void)addLocation:(MAPLocation*)location;

/**
 Adds all locations from a GPX file to the sequence.
 
 @param path The file path to the GPX file.
 @param done The execution block to be executed after the process has finished.
 */
- (void)addGpx:(NSString*)path done:(void(^)(void))done;

///-----------------------------------------------------------------------------
/// @name Getting locations
///-----------------------------------------------------------------------------

/**
 Gets the locations in this sequence as an array of `MAPLocation` objects.
 
 @param locations The images in this sequence.
 @see MAPLocation
 */
- (void)getLocationsAsync:(void(^)(NSArray* locations))locations;

/**
 Gets the location for a specific date.
 
 @param date The date the desired location.
 @see MAPLocation
 */
- (MAPLocation*)locationForDate:(NSDate*)date;

///-----------------------------------------------------------------------------
/// @name Processing images
///-----------------------------------------------------------------------------

/**
 Adds Mapillary EXIF tags from the GPX file and also updates the GPS tags.
 
 @param image The image that should be processed.
 @see MAPImage
 */
- (void)processImage:(MAPImage*)image;

///-----------------------------------------------------------------------------
/// @name Determining lock status
///-----------------------------------------------------------------------------

/**
 Determines if this sequence is locked for editing.
 
 @return YES if the sequence is locked for editing, NO otherwise.
 */
- (BOOL)isLocked;

///-----------------------------------------------------------------------------
/// @name Saving property changes
///-----------------------------------------------------------------------------

/**
 Saves any property changes you have made to this sequence. Note that changes
 aren't saved automatically because it requires a complete rewrite of the
 internal GPX file and thus is very slow.
 
 @param done Execution block performed when the process is finished.
 */
- (void)savePropertyChanges:(void(^)(void))done;

/**
 Checks if there is a GPX file generated or not.
 */
- (BOOL)hasGpxFile;

///-----------------------------------------------------------------------------
/// @name Getting a preview image
///-----------------------------------------------------------------------------

/**
 Returns a MAPImage object suitable for a visual preview of this sequence.
 
 @return A preview MAPImage.
 */
- (MAPImage*)getPreviewImage;

@end
