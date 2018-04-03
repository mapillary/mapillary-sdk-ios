//
//  MAPImage.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MAPLocation.h"
#import "MAPUser.h"

/**
 The `MAPImage` class encapsulates the information about an image.
 */
@interface MAPImage : NSObject

///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 The date the image was captured.
 */
@property NSDate* captureDate;

/**
 The path to the image file on disk.
 */
@property NSString* imagePath;

/**
 The location the image was captured.
 */
@property MAPLocation* location;

/**
 The user that captured the image.
 */
@property MAPUser* author;

///-----------------------------------------------------------------------------
/// @name Initializers
///-----------------------------------------------------------------------------

/**
 Creates an image object with the currently logged in user and the current date.
 */
- (id)init;

/**
 Creates an image object with the currently logged in user and the current date.
 If a file exists at the path and a thumbnail is missing, one is created.
 
 @param path The path to the image file.
 */
- (id)initWithPath:(NSString*)path;

///-----------------------------------------------------------------------------
/// @name Image loading
///-----------------------------------------------------------------------------

/**
 Loads the full-size image file as an `UIImage`.
 
 @return The loaded image.
 */
- (UIImage*)loadImage;

/**
 Loads a low resulution version of the image file as an `UIImage`.
 
 @return The loaded image.
 */
- (UIImage*)loadThumbnailImage;

///-----------------------------------------------------------------------------
/// @name Misc
///-----------------------------------------------------------------------------

/**
 Returns the file path to the thumbnail.
 
 @return The file path to the thumbnail.
 */
- (NSString*)thumbPath;

/**
 Returns the lock status. When a `MAPImage` is scheduled for processing or
 uploading, it is locked until the operation is complete. When a `MAPImage` is
 locked it cannot be modified or deleted.
 
 @return If the file is locked not not.
 */
- (BOOL)isLocked;

@end
