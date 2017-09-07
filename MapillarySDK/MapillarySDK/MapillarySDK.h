//
//  MapillarySDK.h
//  Mapillary
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for MapillarySDK.
FOUNDATION_EXPORT double MapillarySDKVersionNumber;

//! Project version string for MapillarySDK.
FOUNDATION_EXPORT const unsigned char MapillarySDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Mapillary/PublicHeader.h>

#import "MAPDevice.h"
#import "MAPFileManager.h"
#import "MAPImage.h"
#import "MAPLocation.h"
#import "MAPLoginManager.h"
#import "MAPSequence.h"
#import "MAPUploadManager.h"
#import "MAPUploadStatus.h"
#import "MAPUser.h"


@interface MapillarySDK : NSObject

+ (void)initWithClientId:(NSString*)clientId andRedirectUrl:(NSString*)redirectUrl;

@end
