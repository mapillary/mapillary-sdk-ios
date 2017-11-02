//
//  MAPApplicationDelegate.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-08.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 The `MAPApplicationDelegate` is used to complete the autehntication process
 initiated by the `MAPLoginManager`. You should add these methods to your
 `UIApplicationDelegate`.
 
 @see MAPLoginManager
 */
@interface MAPApplicationDelegate : NSObject

/**
 Make sure to call this method in the same method in your
 'UIApplicationDelegate'.
 
 @param application Forward this parameter.
 @param launchOptions Forward this parameter.
 */
+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

/**
 Make sure to call this method in the same method in your
 'UIApplicationDelegate'.
 
 @param application Forward this parameter.
 @param url Forward this parameter.
 @param sourceApplication Forward this parameter.
 @param annotation Forward this parameter.
 */
+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end
