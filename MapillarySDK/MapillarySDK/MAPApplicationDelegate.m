//
//  MAPApplicationDelegate.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-08.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPApplicationDelegate.h"
#import "MAPApiManager.h"
#import "MAPDefines.h"

@implementation MAPApplicationDelegate

+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // TODO
    return [self handleLoginWithUrl:nil];
}

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self handleLoginWithUrl:url];
}

+ (BOOL)handleLoginWithUrl:(NSURL*)url
{
    BOOL ok = NO;
    
    NSString* redirectUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MapillaryRedirectUrl"];
    
    if ([url.scheme isEqualToString:redirectUrl])
    {
        NSMutableDictionary* queryStringDictionary = [[NSMutableDictionary alloc] init];
        NSArray* urlComponents = [url.absoluteString componentsSeparatedByString:@"&"];
        
        for (NSString* keyValuePair in urlComponents)
        {
            NSArray* pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString* key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString* value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            
            [queryStringDictionary setObject:value forKey:key];
        }
        
        NSString* access_token = queryStringDictionary[@"access_token"];
        
        if (access_token && access_token.length > 0)
        {
            ok = YES;
            
            [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];
        }
        
        [MAPApiManager getCurrentUser:^(MAPUser *user) {
            
            if (user)
            {
                NSString* user_name = user.userName;
                NSString* user_key = user.userKey;
                
                [[NSUserDefaults standardUserDefaults] setObject:user_name forKey:MAPILLARY_CURRENT_USER_NAME];
                [[NSUserDefaults standardUserDefaults] setObject:user_key forKey:MAPILLARY_CURRENT_USER_KEY];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MAPILLARY_NOTIFICATION_LOGIN object:nil userInfo:@{@"success": [NSNumber numberWithBool:ok]}];
            
        }];
    }

    return ok;
}

@end
