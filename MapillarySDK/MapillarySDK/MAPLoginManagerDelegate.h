//
//  MAPLoginManagerDelegate.h
//  MapillarySDK
//
//  Created by martensson on 2020-08-06.
//

#import <Foundation/Foundation.h>

@class MAPLoginManager;

@protocol MAPLoginManagerDelegate <NSObject>

@optional

/**
 Delegate method for when the user was logged out.
 
 @param loginManager The login manager object that is .
 @param user The user that was logged out.
 @param reason A string that is used to explain why the user was signed out.
 */
- (void)userWasSignedOut:(MAPLoginManager*)loginManager user:(MAPUser*)user reason:(NSString*)reason;

@end
