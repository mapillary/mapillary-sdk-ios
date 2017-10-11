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
    // com.mapillary.sdk.ios://?token_type=bearer&access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJtcHkiLCJzdWIiOiJXNVVMMUQ3ZGVCRE8zSkI4Vi1vX1B3IiwiYXVkIjoiVnpWVlRERkVOMlJsUWtSUE0wcENPRll0YjE5UWR6bzRNR1k0TUdSbFpqTTJOakF6TnpRdyIsImlhdCI6MTUwNDcyOTQyNjE3NywianRpIjoiODE4NTgzODQ2ZjBjYTAyMDI2ZWQ4NDI0ODVjYzY2NGUiLCJzY28iOlsidXNlcjpyZWFkIl0sInZlciI6MX0.1zBYA98pDgogM0z7bQbH4Cei49j_fd-t-wVor45tRpY&expires_in=never
    
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
        
        NSString* access_token = queryStringDictionary[@"access_token"];
        
        if (access_token && access_token.length > 0)
        {
            ok = YES;
        }
        
        [MAPApiManager getCurrentUser:^(MAPUser *user) {
            
            if (user)
            {
                NSString* user_name = user.userName;
                NSString* user_key = user.userKey;
                
                [[NSUserDefaults standardUserDefaults] setObject:user_name forKey:MAPILLARY_CURRENT_USER_NAME];
                [[NSUserDefaults standardUserDefaults] setObject:user_key forKey:MAPILLARY_CURRENT_USER_KEY];
                [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];             

            }
        }];
    }

    return ok;
}

@end
