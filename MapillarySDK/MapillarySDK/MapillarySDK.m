//
//  MapillarySDK.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MapillarySDK.h"
#import "MAPDefines.h"

@interface MapillarySDK()

@property NSString* clientId;

@end

@implementation MapillarySDK

+ (void)initWithClientId:(NSString*)clientId
{
    [[NSUserDefaults standardUserDefaults] setObject:clientId forKey:MAPILLARY_CLIENT_ID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
