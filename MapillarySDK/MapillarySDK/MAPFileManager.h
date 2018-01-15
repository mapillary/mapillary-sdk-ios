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

+ (void)listSequences:(void(^)(NSArray* sequences))done;
+ (void)deleteSequence:(MAPSequence*)sequence;


@end
