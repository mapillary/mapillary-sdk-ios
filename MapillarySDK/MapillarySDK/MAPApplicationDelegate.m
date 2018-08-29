//
//  MAPApplicationDelegate.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-08.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPApplicationDelegate.h"
#import "MAPApiManager.h"
#import "MAPDefines.h"
#import "MAPUploadManager.h"
#import "MAPUploadManager+Private.h"

@implementation MAPApplicationDelegate

+ (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    [MAPUploadManager sharedManager].backgroundUploadSessionCompletionHandler = completionHandler;
}

@end
