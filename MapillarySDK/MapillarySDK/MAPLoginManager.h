//
//  MAPLoginManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUser.h"
#import "MAPLoginViewController.h"

typedef NS_ENUM(NSInteger, MAPScope) {
    MAPScopeUserEmail,
    MAPScopeUserRead,
    MAPScopeUserWrite,
    MAPScopePublicWrite,
    MAPScopePublicUpload,
    MAPScopePrivateRead,
    MAPScopePrivateWrite,
    MAPScopePrivateUpload,
    MAPScopeAll,
};

typedef NS_OPTIONS(NSUInteger, MAPScopeMask) {
    MAPScopeMaskUserEmail = (1 << MAPScopeUserEmail),
    MAPScopeMaskUserRead = (1 << MAPScopeUserRead),
    MAPScopeMaskUserWrite = (1 << MAPScopeUserWrite),
    MAPScopeMaskPublicWrite = (1 << MAPScopePublicWrite),
    MAPScopeMaskPublicUpload = (1 << MAPScopePublicUpload),
    MAPScopeMaskPrivateRead = (1 << MAPScopePrivateRead),
    MAPScopeMaskPrivateWrite = (1 << MAPScopePrivateWrite),
    MAPScopeMaskPrivateUpload = (1 << MAPScopePrivateUpload),
    MAPScopeMaskAll = (MAPScopeMaskUserEmail | MAPScopeMaskUserRead | MAPScopeMaskUserWrite | MAPScopeMaskPublicWrite | MAPScopeMaskPublicUpload | MAPScopeMaskPrivateRead | MAPScopeMaskPrivateWrite | MAPScopeMaskPrivateUpload)
};

/**
 The `MAPLoginManager` class manages the authentication of Mapillary. The
 signIn method starts the authentication loop. It requires two values to be
 defined in your application `.plist` file:
 
 - MapillaryClientId
 - MapillaryRedirectUrl
 
 You need to register your app at mapillary.com to enter the redirect URL and
 also to obtain a client ID. Your app must also support the custom URL scheme
 defined in `MapillaryRedirectUrl`.
 
 @see `MAPApplicationDelegate`
 */
@interface MAPLoginManager : NSObject <MAPLoginViewControllerDelegate>

///-----------------------------------------------------------------------------
/// @name Authentication
///-----------------------------------------------------------------------------

/**
 Redirects the user to an authentication page on mapillary.com in Safari.
 After the user has entered the credentials and is authenticated, focus is
 returned to the app.
 
 @oaram scope A bit mask for the scope of permissions to request. Must match
 what you configured when created the app on mapillary.com.
 @param result A block object that is executed when the authentication loop
 finishes. This block has no return value and takes one argument: if
 authentication was sucessful or not.
 */
+ (void)signInFromViewController:(UIViewController*)viewController scope:(MAPScopeMask)scope result:(void (^) (BOOL success))result cancelled:(void (^) (void))cancelled;

/**
 Signs out the current signed in user and removes all related user data.
 */
+ (void)signOut;

///-----------------------------------------------------------------------------
/// @name Current user
///-----------------------------------------------------------------------------

/**
 Checks if a user is signed in or not.
 
 @return YES if a user is signed in, NO if no user is signed in.
 */
+ (BOOL)isSignedIn;

/**
 Returns the currently signed in user.
 
 @return The signed in user if a user is signed in, nil if no user is signed in.
 */
+ (MAPUser*)currentUser;

@end
