//
//  MAPSequence+Private.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-01-25.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPSequence.h"

@interface MAPSequence(Private)

- (void)lock;
- (void)unlock;
- (NSMutableDictionary*)meta;

@end
