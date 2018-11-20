//
//  MAPApiManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-07.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUser.h"

@interface MAPApiManager : NSObject

+ (void)getCurrentUser:(void(^)(MAPUser* user))done;

@end
