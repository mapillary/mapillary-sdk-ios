//
//  MAPExifTools.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-02-01.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPExifTools.h"
#import "MAPSequence+Private.h"
#import "MAPDefines.h"

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
                NSString* MAPLatitude = json[kMAPLatitude];
                NSString* MAPLongitude = json[kMAPLongitude];
                
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
        // Prepare
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)image.imagePath, NULL);
        CFStringRef UTI = CGImageSourceGetType(imageSource);
        NSMutableData* imageData = [NSMutableData dataWithContentsOfFile:image.imagePath];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, UTI, 1, NULL);

        // GPS part
        MAPLocation* adjustedLocation = [sequence locationForDate:image.captureDate];
        NSDictionary* gpsDictionary = [self gpsDictionaryFromLocation:adjustedLocation];
        
        // Description
        NSMutableDictionary* description = [sequence meta];
        description[kMAPLatitude] = [NSNumber numberWithDouble:adjustedLocation.location.coordinate.latitude];
        description[kMAPLongitude] = [NSNumber numberWithDouble:adjustedLocation.location.coordinate.longitude];
        description[kMAPCaptureTime] = image.captureDate; // TODO string
        description[kMAPGpsTime] = image.location.timestamp; // TODO string
        
        
        
        //
        //dict[kMAPCompassHeading] = @{kMAPTrueHeading: @"", kMAPMagneticHeading: @""};
        
        
        /*#
         #define          @"MAPCaptureTime"
         #define              @"MAPGpsTime"
         #define kMAPDirection           @"MAPDirection"
         #define kMAPCompassHeading      @"MAPCompassHeading"
         #define kMAPTrueHeading         @"TrueHeading"
         #define kMAPMagneticHeading     @"MagneticHeading"
         #define kMAPGPSAccuracyMeters   @"MAPGPSAccuracyMeters"
         #define kMAPAccelerometerVector @"MAPAccelerometerVectorMAPAtanAngle"*/
        
        
        // Combine all dictionaries
        NSDictionary* exifOriginal = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        NSMutableDictionary* metaCopy = [exifOriginal mutableCopy];
        metaCopy[(NSString *)kCGImagePropertyExifDictionary] = description;
        metaCopy[(NSString *)kCGImagePropertyGPSDictionary] = gpsDictionary;
        metaCopy[(NSString *)kCGImageDestinationMergeMetadata] = @YES; // Makes sure we just merge the new meta data instead of overwriting it
        
        // Write new data to image
        CFErrorRef errorRef = nil;
        if (!CGImageDestinationCopyImageSource(destination, imageSource, (__bridge CFDictionaryRef)metaCopy, &errorRef))
        {
            CFStringRef error_description = CFErrorCopyDescription(errorRef);
            CFRelease(error_description);
        }
        
        // Write to disk
        [imageData writeToFile:image.imagePath atomically:YES];
        
        // Cleanup
        CFRelease(destination);
        CFRelease(imageSource);
        imageData = nil;
    }
}

#pragma mark - Internal

+ (NSDictionary*)gpsDictionaryFromLocation:(MAPLocation*)location
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    CLLocationDegrees latitude  = location.location.coordinate.latitude;
    CLLocationDegrees longitude = location.location.coordinate.longitude;
    
    NSString* latitudeRef = nil;
    NSString* longitudeRef = nil;
    
    if (latitude < 0.0)
    {
        latitude *= -1;
        latitudeRef = @"S";
        
    }
    else
    {
        latitudeRef = @"N";
    }
    
    if (longitude < 0.0)
    {
        longitude *= -1;
        longitudeRef = @"W";
        
    }
    else
    {
        longitudeRef = @"E";
        
    }
    
    dict[(NSString*)kCGImagePropertyGPSTimeStamp] = [self getUTCFormattedDate:location.location.timestamp];
    dict[(NSString*)kCGImagePropertyGPSDateStamp] = [self getUTCFormattedDate:location.location.timestamp]; // TODO change format
    
    dict[(NSString*)kCGImagePropertyGPSLatitudeRef] = latitudeRef;
    dict[(NSString*)kCGImagePropertyGPSLatitude] = [NSNumber numberWithFloat:latitude];
    
    dict[(NSString*)kCGImagePropertyGPSLongitudeRef] = longitudeRef;
    dict[(NSString*)kCGImagePropertyGPSLongitude] = [NSNumber numberWithFloat:longitude];
    
    dict[(NSString*)kCGImagePropertyGPSDOP] = [NSNumber numberWithFloat:location.location.horizontalAccuracy];
    dict[(NSString*)kCGImagePropertyGPSAltitude] = [NSNumber numberWithFloat:location.location.altitude];
    
    return dict;
}

+ (NSString*)getUTCFormattedDate:(NSDate*)localDate
{
    static NSDateFormatter* dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy:MM:dd HH:mm:ss";
        
    });
        
    return [dateFormatter stringFromDate:localDate];
}

@end
