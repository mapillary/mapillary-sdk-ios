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
 The `MAPApplicationDelegate` is used to handle the background uploading process
 initiated by `MAPUploadManager`. You should add these methods to your
 `UIApplicationDelegate`.
 
 @see `MAPLoginManager`
 */
@interface MAPApplicationDelegate : NSObject

/**
 Make sure to call this method in the same method in your
 'UIApplicationDelegate'.
 
 @param application Forward this parameter.
 @param identifier Forward this parameter.
 @param completionHandler Forward this parameter.
 */
+ (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;

@end
