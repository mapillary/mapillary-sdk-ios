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

@implementation MAPLoginManager

+ (void)signIn
{
    // TODO
    
    NSString* redirectUrl = @"anders"; //@"VzVVTDFEN2RlQkRPM0pCOFYtb19QdzozNDBkYmQ3ZmFiNTVmOTIz"; //@"http://com.mapillary.sdk.ios"; //[[NSUserDefaults standardUserDefaults] objectForKey:MAPILLARY_CLIENT_ID];
    NSString* clientId = @"VzVVTDFEN2RlQkRPM0pCOFYtb19QdzozNDBkYmQ3ZmFiNTVmOTIz";
    //NSString* url = [NSString stringWithFormat:@"https://www.mapillary.com/connect?scope=user:read&state=return&redirect_uri=%@://&response_type=token&client_id=%@", redirectUrl, clientId];
    NSString* url = [NSString stringWithFormat:@"https://www.mapillary.com/connect?scope=user:read&state=return&redirect_uri=%@&response_type=token&client_id=%@", redirectUrl, clientId];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    
    //[[NSUserDefaults standardUserDefaults] setObject:@"username" forKey:MAPILLARY_CURRENT_USER_NAME];
    //[[NSUserDefaults standardUserDefaults] setObject:@"userkey" forKey:MAPILLARY_CURRENT_USER_KEY];
    //[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)signOut
{
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
