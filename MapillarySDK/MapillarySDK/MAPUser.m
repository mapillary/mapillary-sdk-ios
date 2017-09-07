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
@property NSString* _uploadHash;

@end

@implementation MAPUser

- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey andUserAccessToken:(NSString*)accessToken
{
    self = [super init];
    if (self)
    {
        self._userName = userName;
        self._userKey = userKey;
        self._accessToken = accessToken;
        self._uploadHash = [NSString stringWithFormat:@"Bearer %@", accessToken];
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

- (NSString*)uploadHash
{
    return self._uploadHash;
}

@end
