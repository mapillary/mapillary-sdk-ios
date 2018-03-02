//
//  AppDelegate.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-10-30.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import "AppDelegate.h"
#import <MapillarySDK/MapillarySDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{    
    [MAPApplicationDelegate interceptApplication:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}

@end
