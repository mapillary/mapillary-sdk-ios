//
//  MAPImage+Private.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-01-25.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPImage+Private.h"

@implementation MAPImage(Private)

- (void)delete
{
    [[NSFileManager defaultManager] removeItemAtPath:self.imagePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self.thumbPath error:nil];
}

- (void)lock
{
    NSString* path = [self.imagePath stringByAppendingPathComponent:@"lock"];
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
}

- (void)unlock
{
    NSString* path = [self.imagePath stringByAppendingPathComponent:@"lock"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
