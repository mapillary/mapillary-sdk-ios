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
#import <PodAsset/PodAsset.h>

static MAPLoginManager* singleInstance;


@interface MAPLoginManager()

@property (copy, nonatomic) void (^loginCompletionHandler)(BOOL);
@property (copy, nonatomic) void (^loginCancelledHandler)(void);

@end

@implementation MAPLoginManager

+ (MAPLoginManager*)getInstance
{
    static dispatch_once_t dispatchOnceToken;
    
    dispatch_once(&dispatchOnceToken, ^{
        
        singleInstance = [[MAPLoginManager alloc] init];
        
    });
    
    return singleInstance;
}

+ (void)signInFromViewController:(UIViewController*)viewController result:(void (^) (BOOL success))result cancelled:(void (^) (void))cancelled
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
    
    NSString* urlString = [NSString stringWithFormat:@"https://www.mapillary.com/connect?scope=user:read&state=return&redirect_uri=%@&response_type=token&client_id=%@", redirectUrl, clientId];
    
    [MAPLoginManager getInstance].loginCompletionHandler = result;
    [MAPLoginManager getInstance].loginCancelledHandler = cancelled;
    
    MAPLoginViewController* loginViewController = [[MAPLoginViewController alloc] initWithNibName:@"MAPLoginViewController" bundle:[PodAsset bundleForPod:@"MapillarySDK"]];
    loginViewController.urlString = urlString;
    loginViewController.delegate = (id<MAPLoginViewControllerDelegate>)[MAPLoginManager getInstance];
    
    [viewController presentViewController:loginViewController animated:YES completion:nil];
    
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
        return [[MAPUser alloc] initWithUserName:userName andUserKey:userKey andAccessToken:userAccessToken];
    }
    
    return nil;
}

#pragma mark - Internal

- (void)didLogin:(MAPLoginViewController*)loginViewController accessToken:(NSString*)accessToken
{
    loginViewController.delegate = nil;
    
    if (accessToken && accessToken.length > 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:MAPILLARY_CURRENT_USER_ACCESS_TOKEN];
        
        [MAPApiManager getCurrentUser:^(MAPUser *user) {
            
            if (user)
            {
                [[NSUserDefaults standardUserDefaults] setObject:user.userName forKey:MAPILLARY_CURRENT_USER_NAME];
                [[NSUserDefaults standardUserDefaults] setObject:user.userKey forKey:MAPILLARY_CURRENT_USER_KEY];
                
                if (self.loginCompletionHandler)
                {
                    [MAPLoginManager getInstance].loginCompletionHandler(YES);
                    [MAPLoginManager getInstance].loginCompletionHandler = nil;
                    [MAPLoginManager getInstance].loginCancelledHandler = nil;
                }
            }
            else
            {
                if ([MAPLoginManager getInstance].loginCompletionHandler)
                {
                    [MAPLoginManager getInstance].loginCompletionHandler(NO);
                    [MAPLoginManager getInstance].loginCompletionHandler = nil;
                    [MAPLoginManager getInstance].loginCancelledHandler = nil;
                }
            }
        }];
    }
    else
    {
        if ([MAPLoginManager getInstance].loginCompletionHandler)
        {
            [MAPLoginManager getInstance].loginCompletionHandler(NO);
            [MAPLoginManager getInstance].loginCompletionHandler = nil;
            [MAPLoginManager getInstance].loginCancelledHandler = nil;
        }
    }
}

- (void)didCancel:(MAPLoginViewController*)loginViewController
{
    if ([MAPLoginManager getInstance].loginCancelledHandler)
    {
        [MAPLoginManager getInstance].loginCancelledHandler();
        [MAPLoginManager getInstance].loginCompletionHandler = nil;
        [MAPLoginManager getInstance].loginCancelledHandler = nil;
    }
}

@end
