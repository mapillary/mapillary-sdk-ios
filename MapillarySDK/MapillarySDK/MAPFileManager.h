//
//  MAPFileManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPSequence.h"
#import "MAPImage.h"

@interface MAPFileManager : NSObject

+ (nonnull NSArray*)listSequences;
+ (void)deleteSequence:(nonnull MAPSequence*)sequence;
+ (void)deleteImage:(nonnull MAPImage*)image;


@end
