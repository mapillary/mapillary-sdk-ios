//
//  MAPUser.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

/** The `MAPUser` class encapsulates the information about a user. */
@interface MAPUser : NSObject

/** The user's username. It can be changed by the user */
@property (readonly) NSString* userName;

/** The unique key to identify the user. The userKey never changes. */
@property (readonly) NSString* userKey;

/** Creates a user object.
 *
 * @param userName The user's user name.
 * @param userKey The unique key to identify the user.
 */
- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey;

@end
