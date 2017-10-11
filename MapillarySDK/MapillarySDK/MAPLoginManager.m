//
//  MAPLoginManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPLoginManager.h"
#import "MAPDefines.h"
#import <UIKit/UIKit.h>
#import "MAPApiManager.h"

@implementation MAPLoginManager

+ (void)signIn
{
    NSString* clientId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString* redirectUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    if (![redirectUrl containsString:@"://"])
    {
        redirectUrl = [redirectUrl stringByAppendingString:@"://"];
    }
    
    NSString* url = [NSString stringWithFormat:@"https://www.mapillary.com/connect?scope=user:read&state=return&redirect_uri=%@&response_type=token&client_id=%@", redirectUrl, clientId];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

+ (void)signOut
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_NAME];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (MAPUser*)currentUser
{
    NSString* userName = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_NAME];
    NSString* userKey = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_KEY];
    NSString* userAccessToken = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];
    
    if (userName && userKey && userAccessToken)
    {
        return [[MAPUser alloc] initWithUserName:userName andUserKey:userKey andUserAccessToken:userAccessToken];
    }
    
    return nil;
}

@end
