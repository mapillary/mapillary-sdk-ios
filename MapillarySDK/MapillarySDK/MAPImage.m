//
//  MAPImage.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPImage.h"
#import "MAPLoginManager.h"
#import "MAPUtils.h"

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
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self thumbPath]])
    {
        float screenWidth = [[UIScreen mainScreen] bounds].size.width;
        float screenHeight = [[UIScreen mainScreen] bounds].size.width;
        CGSize thumbSize = CGSizeMake(screenWidth/3-1, screenHeight/3-1);
        [MAPUtils createThumbnailForImage:[self loadImage] atPath:[self thumbPath] withSize:thumbSize];
    }
    
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
    if (self.imagePath)
    {
        return [NSString stringWithFormat:@"%@-thumb.jpg", [self.imagePath substringToIndex:self.imagePath.length-4]];
    }
    
    return nil;
}

- (BOOL)isLocked
{
    NSString* path = [self.imagePath stringByAppendingPathExtension:@"lock"];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

@end
