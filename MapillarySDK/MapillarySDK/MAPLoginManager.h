//
//  MAPLoginManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUser.h"

@interface MAPLoginManager : NSObject

+ (void)signIn:(void (^) (BOOL success))result;
+ (void)signOut;
+ (BOOL)isSignedIn;

+ (MAPUser*)currentUser;

@end
