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

static MAPLoginManager* singleInstance;

@interface MAPLoginManager()

@property dispatch_semaphore_t semaphore;
@property BOOL loginSuccess;

@end

@implementation MAPLoginManager

+ (MAPLoginManager*)getInstance
{
    static dispatch_once_t dispatchOnceToken;
    
    dispatch_once(&dispatchOnceToken, ^{
        
        singleInstance = [[MAPLoginManager alloc] init];
        singleInstance.semaphore = nil;
        singleInstance.loginSuccess = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:singleInstance selector:@selector(didLogin:) name:MAPILLARY_NOTIFICATION_LOGIN object:nil];
        
    });
    
    return singleInstance;
}

+ (void)signIn:(void (^) (BOOL success))result
{
    NSString* clientId = [[NSBundle mainBundle] objectForInfoDictionaryKey:MAPILLARY_CLIENT_ID];
    NSString* redirectUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:MAPILLARY_CLIENT_REDIRECT_URL];
    
    // Check that clientId and redirectUrl are set
    NSAssert(clientId != nil, @"MapillaryClientId is not specified in application plist file");
    NSAssert(redirectUrl != nil, @"MapillaryRedirectUrl is not specified in application plist file");
    
    // If we don't include :// in the redirect URL, the backend won't launch the app
    if (![redirectUrl containsString:@"://"])
    {
        redirectUrl = [redirectUrl stringByAppendingString:@"://"];
    }
    
    NSString* url = [NSString stringWithFormat:@"https://www.mapillary.com/connect?scope=user:read&state=return&redirect_uri=%@&response_type=token&client_id=%@", redirectUrl, clientId];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    
    // Wait here until login loop finishes
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [MAPLoginManager getInstance].semaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_wait([MAPLoginManager getInstance].semaphore, DISPATCH_TIME_FOREVER);
        
        if (result)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                result([MAPLoginManager getInstance].loginSuccess);
            });
        }
    });
}

+ (void)signOut
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_NAME];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isSignedIn
{
    return [self currentUser] != nil;
}

+ (MAPUser*)currentUser
{
    NSString* userName = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_NAME];
    NSString* userKey = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_KEY];
    NSString* userAccessToken = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];
    
    if (userName && userKey && userAccessToken)
    {
        return [[MAPUser alloc] initWithUserName:userName andUserKey:userKey];
    }
    
    return nil;
}

#pragma mark - Internal

- (void)didLogin:(NSNotification*)notification
{
    NSNumber* success = notification.userInfo[@"success"];
    [MAPLoginManager getInstance].loginSuccess = success.boolValue;
    
    // Login loop done, continue
    dispatch_semaphore_signal([MAPLoginManager getInstance].semaphore);
    [MAPLoginManager getInstance].semaphore = nil;
}

@end
