//
//  MAPUser.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPUser : NSObject

@property (readonly) NSString* userName;
@property (readonly) NSString* userKey;

- (id)initWithUserName:(NSString*)userName andUserKey:(NSString*)userKey;

@end
