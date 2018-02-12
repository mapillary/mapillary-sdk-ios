//
//  MAPSequence+Private.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-01-25.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPSequence+Private.h"

@implementation MAPSequence(Private)

- (void)lock
{
    NSString* path = [self.path stringByAppendingPathComponent:@"lock"];
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
}

- (void)unlock
{
    NSString* path = [self.path stringByAppendingPathComponent:@"lock"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
