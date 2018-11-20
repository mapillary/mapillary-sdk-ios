//
//  MAPUser.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The `MAPUser` class encapsulates the information about a user.
 */
@interface MAPUser : NSObject

///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 The user's username. It can be changed by the user.
 */
@property (readonly) NSString* userName;

/**
 The unique key to identify the user. The userKey never changes.
 */
@property (readonly) NSString* userKey;

/**
 The user's email adress. It can be changed by the user. It will only be
 non-nil for the currently signed in user.
 */
@property (readonly) NSString* userEmail;

/**
 The user's access token. It will only be non-nil for the currently signed in
 user.
 
 @see [MAPLoginManager currentUser]
 */
@property (readonly) NSString* accessToken;

///-----------------------------------------------------------------------------
/// @name Initializers
///-----------------------------------------------------------------------------

/**
 Creates a user object.
 
 @param userName The user's user name.
 @param userKey The unique key to identify the user.
 */
- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey;

/**
 Creates a user object.
 
 @param userName The user's user name.
 @param userKey The unique key to identify the user.
 @param userEmail The user's email adress.
 @param accessToken The access token to be used with API calls.
 */
- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey andUserEmail:(NSString*)userEmail andAccessToken:(NSString*)accessToken;

@end
