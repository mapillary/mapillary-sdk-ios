//
//  MAPExifTools.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-02-01.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPExifTools.h"

@implementation MAPExifTools

+ (BOOL)imageHasMapillaryTags:(MAPImage*)image
{
    NSData* imageData = [NSData dataWithContentsOfFile:image.imagePath];
    return [self imageDataHasMapillaryTags:imageData];
}

+ (BOOL)imageDataHasMapillaryTags:(NSData*)imageData
{
    BOOL ok = NO;
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)(imageData), NULL);
    
    if (source)
    {
        CFDictionaryRef cfDict = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
        NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(cfDict);
        NSDictionary* TIFF = [metadata objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        
        if (TIFF)
        {
            NSString* description = [TIFF objectForKey:(NSString *)kCGImagePropertyTIFFImageDescription];
            
            if (description)
            {
                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:[description dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                NSString* MAPLatitude = [json objectForKey:@"MAPLatitude"];
                NSString* MAPLongitude = [json objectForKey:@"MAPLongitude"];
                
                // TODO add more?
                
                ok = MAPLatitude && MAPLongitude;
            }
        }
        
        CFRelease(source);
    }
    
    return ok;
}

+ (void)addExifTagsToImage:(MAPImage*)image fromSequence:(MAPSequence*)sequence
{
    // TODO
    
    if (![self imageHasMapillaryTags:image])
    {
        NSDate* imageDate = image.captureDate;
        [sequence locationForDate:imageDate];
    }
    
}

@end
