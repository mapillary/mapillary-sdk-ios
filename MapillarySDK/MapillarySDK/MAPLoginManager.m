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

+ (void)signInFromViewController:(UIViewController*)viewController scope:(MAPScopeMask)scope result:(void (^) (BOOL success))result cancelled:(void (^) (void))cancelled
{
    NSString* clientId = [[NSBundle mainBundle] objectForInfoDictionaryKey:MAPILLARY_CLIENT_ID];
    NSString* redirectUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:MAPILLARY_CLIENT_CALLBACK_URL];
    
    // Check that clientId and redirectUrl are set
    NSAssert(clientId != nil, @"MapillaryClientId is not specified in application plist file");
    NSAssert(redirectUrl != nil, @"MapillaryCallbackUrl is not specified in application plist file");
     
    NSMutableString* scopeString = [NSMutableString string];
    
    if (scope & MAPScopeMaskUserEmail)
    {
        [scopeString appendString:@"user:email%20"];
    }
    if (scope & MAPScopeMaskUserRead)
    {
        [scopeString appendString:@"user:read%20"];
    }
    if (scope & MAPScopeMaskUserWrite)
    {
        [scopeString appendString:@"user:write%20"];
    }
    if (scope & MAPScopeMaskPublicWrite)
    {
        [scopeString appendString:@"public:write%20"];
    }
    if (scope & MAPScopeMaskPublicUpload)
    {
        [scopeString appendString:@"public:upload%20"];
    }
    if (scope & MAPScopeMaskPrivateRead)
    {
        [scopeString appendString:@"private:read%20"];
    }
    if (scope & MAPScopeMaskPrivateWrite)
    {
        [scopeString appendString:@"private:write%20"];
    }
    if (scope & MAPScopeMaskPrivateUpload)
    {
        [scopeString appendString:@"private:upload%20"];
    }
    
    if (scopeString.length > 0 && [[scopeString substringFromIndex:scopeString.length-3] isEqualToString:@"%20"])
    {
        scopeString = [NSMutableString stringWithString:[scopeString substringToIndex:scopeString.length-3]];
    }
    
    NSString* urlString = [NSString stringWithFormat:@%@/connect?scope=%@&state=return&redirect_uri=%@&response_type=token&client_id=%@&simple=true", kMAPAuthEndpoint, scopeString, redirectUrl, clientId];


    NSString* staging = NSBundle.mainBundle.infoDictionary[@"STAGING"];
    if (staging && staging.intValue == 1)
    {
        [NSString stringWithFormat:@%@/connect?scope=%@&state=return&redirect_uri=%@&response_type=token&client_id=%@&simple=true", kMAPAuthEndpointStaging, scopeString, redirectUrl, clientId];
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
