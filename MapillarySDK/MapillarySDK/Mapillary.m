//
//  Mapillary.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "Mapillary.h"
#import "Defines.h"

@interface Mapillary()

@property NSString* clientId;

@end

@implementation Mapillary

+ (void)initWithClientId:(NSString*)clientId
{
    [[NSUserDefaults standardUserDefaults] setObject:clientId forKey:MAPILLARY_CLIENT_ID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
