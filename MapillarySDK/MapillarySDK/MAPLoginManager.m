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
    NSString* redirectUrl = [[NSUserDefaults standardUserDefaults] objectForKey:MAPILLARY_REDIRECT_URL];
    NSString* clientId = [[NSUserDefaults standardUserDefaults] objectForKey:MAPILLARY_CLIENT_ID];
    NSString* url = [NSString stringWithFormat:@"https://www.mapillary.com/connect?scope=user:read&state=return&redirect_uri=%@://&response_type=token&client_id=%@", redirectUrl, clientId];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

+ (BOOL)finishSignIn:(NSURL*)url
{
    BOOL ok = NO;
    
    NSString* redirectUrl = @"com.mapillary.sdk.ios";
    
    if ([url.scheme isEqualToString:redirectUrl])
    {
        NSMutableDictionary* queryStringDictionary = [[NSMutableDictionary alloc] init];
        NSArray* urlComponents = [url.parameterString componentsSeparatedByString:@"&"];
        
        for (NSString* keyValuePair in urlComponents)
        {
            NSArray* pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString* key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString* value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            
            [queryStringDictionary setObject:value forKey:key];
        }
        
        // com.mapillary.sdk.ios://?token_type=bearer&access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJtcHkiLCJzdWIiOiJXNVVMMUQ3ZGVCRE8zSkI4Vi1vX1B3IiwiYXVkIjoiVnpWVlRERkVOMlJsUWtSUE0wcENPRll0YjE5UWR6bzRNR1k0TUdSbFpqTTJOakF6TnpRdyIsImlhdCI6MTUwNDcyOTQyNjE3NywianRpIjoiODE4NTgzODQ2ZjBjYTAyMDI2ZWQ4NDI0ODVjYzY2NGUiLCJzY28iOlsidXNlcjpyZWFkIl0sInZlciI6MX0.1zBYA98pDgogM0z7bQbH4Cei49j_fd-t-wVor45tRpY&expires_in=never
        
        NSString* access_token = queryStringDictionary[@"access_token"];
        NSString* user_name = queryStringDictionary[@"user_name"];
        NSString* user_key = queryStringDictionary[@"user_key"];
        
        if (access_token && access_token.length > 0)
        {
            ok = YES;
            
            [[NSUserDefaults standardUserDefaults] setObject:user_name forKey:MAPILLARY_CURRENT_USER_NAME];
            [[NSUserDefaults standardUserDefaults] setObject:user_key forKey:MAPILLARY_CURRENT_USER_KEY];
            [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    return ok;
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
