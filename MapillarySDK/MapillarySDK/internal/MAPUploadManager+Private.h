//
//  MAPUploadManager+Private.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-04-04.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPUploadManager.h"

@interface MAPUploadManager(Private)

@property (nonatomic) void (^backgroundUploadSessionCompletionHandler)(void);

@end
