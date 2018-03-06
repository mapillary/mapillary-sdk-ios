//
//  MAPUtils.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-10-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MAPLocation.h"

@interface MAPUtils : NSObject

+ (void)createThumbnailForImage:(UIImage*)sourceImage atPath:(NSString*)path withSize:(CGSize)size;

@end
