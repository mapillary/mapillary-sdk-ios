//
//  MAPImage.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPImage.h"
#import "MAPLoginManager.h"

@implementation MAPImage

- (id)init
{
    self = [super init];
    if (self)
    {
        self.captureDate = [NSDate date];
        self.author = [MAPLoginManager currentUser];
    }
    return self;
}

- (id)initWithPath:(NSString*)path
{
    self = [self init];
    self.imagePath = path;
    
    return self;
}

- (UIImage*)loadImage
{
    if (self.imagePath)
    {
        return [UIImage imageWithContentsOfFile:self.imagePath];
    }
    
    return nil;
}

- (UIImage*)loadThumbnailImage
{
    if (self.imagePath)
    {
        return [UIImage imageWithContentsOfFile:[self thumbPath]];
    }
    
    return nil;
}

- (NSString*)thumbPath
{
    return [NSString stringWithFormat:@"%@-thumb.jpg", [self.imagePath substringToIndex:self.imagePath.length-4]];
}

- (BOOL)isLocked
{
    NSString* path = [self.imagePath stringByAppendingPathComponent:@"lock"];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

@end
