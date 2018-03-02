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
 
 @param result A block object that is executed when the authentication loop
 finishes. This block has no return value and takes one argument: if
 authentication was sucessful or not.
 */
+ (void)signInFromViewController:(UIViewController*)viewController result:(void (^) (BOOL success))result cancelled:(void (^) (void))cancelled;

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
