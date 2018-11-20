//
//  MAPImage+Private.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-01-25.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPImage.h"

@interface MAPImage(Private)

- (void)delete;
- (void)lock;
- (void)unlock;

@end
