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
#import <SAMKeychain/SAMKeychain.h>
#import "MAPLoginViewController.h"

static MAPLoginManager* singleInstance;


@interface MAPLoginManager()

@property (copy, nonatomic) void (^loginCompletionHandler)(BOOL);
@property (copy, nonatomic) void (^loginCancelledHandler)(void);
@property MAPUser* user;

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
    NSAssert(clientId != nil, @"MapillaryClientId is not specified in application plist file");

    NSString* urlString = [NSString stringWithFormat:@"%@/connect?client_id=%@&simple=true", kMAPAuthEndpoint, clientId];
    
    NSString* staging = NSBundle.mainBundle.infoDictionary[@"STAGING"];
    if (staging && staging.intValue == 1)
    {
        urlString = [NSString stringWithFormat:@"%@/connect?client_id=%@&simple=true", kMAPAuthEndpointStaging, clientId];
    }
    
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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_EMAIL];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    for (NSString* account in [SAMKeychain accountsForService:MAPILLARY_KEYCHAIN_SERVICE])
    {
        [SAMKeychain deletePasswordForService:MAPILLARY_KEYCHAIN_SERVICE account:account];
    }
    
    [self getInstance].user = nil;
}

+ (BOOL)isSignedIn
{
    return [self currentUser] != nil;
}

+ (MAPUser*)currentUser
{
    if ([self getInstance].user == nil)
    {
        NSString* userName = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_NAME];
        NSString* userKey = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_KEY];
        NSString* userEmail = [[NSUserDefaults standardUserDefaults] stringForKey:MAPILLARY_CURRENT_USER_EMAIL];
        NSString* userAccessToken = [SAMKeychain passwordForService:MAPILLARY_KEYCHAIN_SERVICE account:MAPILLARY_KEYCHAIN_ACCOUNT];
        
        if (userName && userKey && userAccessToken)
        {
            [self getInstance].user = [[MAPUser alloc] initWithUserName:userName andUserKey:userKey andUserEmail:userEmail andAccessToken:userAccessToken];
        }
        else
        {
            [self getInstance].user = nil;
        }
    }
    
    return [self getInstance].user;
}

#pragma mark - Internal

- (void)didLogin:(MAPLoginViewController*)loginViewController accessToken:(NSString*)accessToken
{
    loginViewController.delegate = nil;
    
    if (accessToken && accessToken.length > 0)
    {
        [SAMKeychain setPassword:accessToken forService:MAPILLARY_KEYCHAIN_SERVICE account:MAPILLARY_KEYCHAIN_ACCOUNT];
        
        [MAPApiManager getCurrentUser:^(MAPUser *user) {
            
            if (user)
            {
                [[NSUserDefaults standardUserDefaults] setObject:user.userName forKey:MAPILLARY_CURRENT_USER_NAME];
                [[NSUserDefaults standardUserDefaults] setObject:user.userKey forKey:MAPILLARY_CURRENT_USER_KEY];
                [[NSUserDefaults standardUserDefaults] setObject:user.userEmail forKey:MAPILLARY_CURRENT_USER_EMAIL];
                
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
