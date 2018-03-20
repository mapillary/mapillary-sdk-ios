//
//  MAPExifTools.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-02-01.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPImage.h"
#import "MAPSequence.h"

@interface MAPExifTools : NSObject

+ (BOOL)imageHasMapillaryTags:(MAPImage*)image;
+ (BOOL)addExifTagsToImage:(MAPImage*)image fromSequence:(MAPSequence*)sequence;

@end
