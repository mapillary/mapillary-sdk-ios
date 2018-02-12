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

@interface MAPImage : NSObject

@property NSDate* captureDate;
@property NSString* imagePath;
@property MAPLocation* location;
@property MAPUser* author;

- (id)init;
- (id)initWithPath:(NSString*)path;
- (UIImage*)loadImage;
- (UIImage*)loadThumbnailImage;
- (NSString*)thumbPath;
- (BOOL)isLocked;

@end
