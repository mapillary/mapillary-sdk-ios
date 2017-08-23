//
//  MAPLoginManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPLoginManager.h"
#import "Defines.h"

@implementation MAPLoginManager

+ (void)signIn
{
    // TODO
    
    [[NSUserDefaults standardUserDefaults] setObject:@"username" forKey:MAPILLARY_CURRENT_USER_NAME];
    [[NSUserDefaults standardUserDefaults] setObject:@"userkey" forKey:MAPILLARY_CURRENT_USER_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)signOut
{
    // TODO
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_NAME];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (MAPUser*)currentUser
{
    NSString* userName = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_NAME];
    NSString* userKey = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_KEY];
    
    if (userName && userKey)
    {
        return [[MAPUser alloc] initWithUserName:userName andUserKey:userKey];
    }
    
    return nil;
}

@end
