//
//  MAPLocation.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPLocation : NSObject

@property double latitude;
@property double longitude;
@property double originalBearing;
@property double calculatedBearing;


@end
