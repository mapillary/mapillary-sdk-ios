//
//  MAPUser.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPUser.h"

@interface MAPUser()

@property NSString* _userName;
@property NSString* _userKey;
@property NSString* _accessToken;

@end

@implementation MAPUser

- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey
{
    return [self initWithUserName:userName andUserKey:userKey andAccessToken:nil];
}

- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey andAccessToken:(NSString*)accessToken
{
    self = [super init];
    if (self)
    {
        self._userName = userName;
        self._userKey = userKey;
        self._accessToken = accessToken;
    }
    return self;
}

- (NSString*)userName
{
    return self._userName;
}

- (NSString*)userKey
{
    return self._userKey;
}

- (NSString*)accessToken
{
    return self._accessToken;
}

@end
