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

@end

@implementation MAPUser

- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey
{
    self = [super init];
    if (self)
    {
        self._userName = userName;
        self._userKey = userKey;
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

@end
