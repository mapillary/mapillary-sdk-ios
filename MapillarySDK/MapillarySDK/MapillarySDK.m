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

+ (void)initWithClientId:(NSString*)clientId andRedirectUrl:(NSString*)redirectUrl;
{
    NSAssert(clientId != nil && clientId.length > 0, @"clientId cannot be nil or empty");
    NSAssert(redirectUrl != nil && redirectUrl.length > 0, @"redirectUrl cannot be nil or empty");
    
    [[NSUserDefaults standardUserDefaults] setObject:clientId forKey:MAPILLARY_CLIENT_ID];
    [[NSUserDefaults standardUserDefaults] setObject:redirectUrl forKey:MAPILLARY_REDIRECT_URL];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
