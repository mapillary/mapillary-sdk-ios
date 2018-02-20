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
#import <MobileCoreServices/MobileCoreServices.h>

@implementation MAPExifTools

+ (BOOL)imageHasMapillaryTags:(MAPImage*)image
{
    BOOL ok = NO;
    
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:image.imagePath], NULL);
    
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
                
                // TODO add more checks?
                
                ok = MAPLatitude && MAPLongitude;
            }
        }
        
        CFRelease(source);
    }
    
    return ok;
}

+ (BOOL)addExifTagsToImage:(MAPImage*)image fromSequence:(MAPSequence*)sequence
{
    BOOL success = YES;
    
    if (![self imageHasMapillaryTags:image])
    {
        // Get source and metadata
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:image.imagePath], NULL);
        CGImageMetadataRef metadata = CGImageSourceCopyMetadataAtIndex(imageSource, 0, NULL);
        CGMutableImageMetadataRef mutableMetadata = CGImageMetadataCreateMutable();
        
        
        // Cleanup existing metadata
        [self cleanMetadata:metadata mutableMetadata:mutableMetadata];
        
        
        // Recalculate GPS position based on time and add to metadata
        MAPLocation* adjustedLocation = [sequence locationForDate:image.captureDate];
        [self addGps:adjustedLocation mutableMetadata:mutableMetadata];
        
        
        // Update and add Mapillary tags to metadata
        
        float atanAngle = atan2(adjustedLocation.deviceMotion.gravity.y, -adjustedLocation.deviceMotion.gravity.x);
        NSDictionary* accelerometerVector = @{@"x": [NSNumber numberWithDouble:-adjustedLocation.deviceMotion.gravity.x],
                                              @"y": [NSNumber numberWithDouble:adjustedLocation.deviceMotion.gravity.y],
                                              @"z": [NSNumber numberWithDouble:adjustedLocation.deviceMotion.gravity.z]};
        
        NSMutableDictionary* description = [sequence meta];
        description[kMAPLatitude] = [NSNumber numberWithDouble:adjustedLocation.location.coordinate.latitude];
        description[kMAPLongitude] = [NSNumber numberWithDouble:adjustedLocation.location.coordinate.longitude];
        description[kMAPCaptureTime] = [self getUTCFormattedTime:image.captureDate];
        description[kMAPGpsTime] = [self getUTCFormattedDate:image.captureDate];
        description[kMAPCompassHeading] = @{kMAPTrueHeading:[NSNumber numberWithDouble:adjustedLocation.heading.trueHeading], kMAPMagneticHeading:[NSNumber numberWithDouble:adjustedLocation.heading.magneticHeading]};
        description[kMAPGPSAccuracyMeters] = [NSNumber numberWithDouble:adjustedLocation.location.horizontalAccuracy];
        description[kMAPAtanAngle] = [NSNumber numberWithDouble:atanAngle];
        description[kMAPAccelerometerVector] = accelerometerVector;
        
        NSData* descriptionJsonData = [NSJSONSerialization dataWithJSONObject:description options:0 error:nil];
        NSString* descriptionString = [[NSString alloc] initWithData:descriptionJsonData encoding:NSUTF8StringEncoding];
        
        [self addTiffMetadata:mutableMetadata tag:@"ImageDescription" type:kCGImageMetadataTypeString value:(__bridge CFStringRef)descriptionString];
        
        
        // Write new metadata to image
        CFMutableDictionaryRef options = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(options, kCGImageDestinationMetadata, mutableMetadata);
        
        CFStringRef UTI = CGImageSourceGetType(imageSource);
        if (UTI == NULL)
        {
            UTI = kUTTypeJPEG;
        }
        
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:image.imagePath], UTI, 1, NULL);
        
        CFErrorRef errorRef = nil;
        success = CGImageDestinationCopyImageSource(destination, imageSource, options, &errorRef);
        
        if (!success)
        {
            CFStringRef error_description = CFErrorCopyDescription(errorRef);
            CFRelease(error_description);
        }
        
        
        // Cleanup
        CFRelease(destination);
        CFRelease(imageSource);
        CFRelease(mutableMetadata);
    }

    return success;
}

#pragma mark - Internal

+ (void)addExifMetadata:(CGMutableImageMetadataRef)container tag:(NSString*)tag type:(CGImageMetadataType)type value:(CFTypeRef)value
{
    NSString* tagPath = [NSString stringWithFormat:@"%@:%@", kCGImageMetadataPrefixExif, tag];
    CGImageMetadataTagRef tagValue = CGImageMetadataTagCreate(kCGImageMetadataNamespaceExif, kCGImageMetadataPrefixExif, (__bridge CFStringRef)tag, type, value);
    CGImageMetadataSetTagWithPath(container, NULL, (__bridge CFStringRef)tagPath, tagValue);
    CFRelease(tagValue);
}

+ (void)addTiffMetadata:(CGMutableImageMetadataRef)container tag:(NSString*)tag type:(CGImageMetadataType)type value:(CFTypeRef)value
{
    NSString* tagPath = [NSString stringWithFormat:@"%@:%@", kCGImageMetadataPrefixTIFF, tag];
    CGImageMetadataTagRef tagValue = CGImageMetadataTagCreate(kCGImageMetadataNamespaceTIFF, kCGImageMetadataPrefixTIFF, (__bridge CFStringRef)tag, type, value);
    CGImageMetadataSetTagWithPath(container, NULL, (__bridge CFStringRef)tagPath, tagValue);
    CFRelease(tagValue);
}

+ (void)cleanMetadata:(CGImageMetadataRef)metadata mutableMetadata:(CGMutableImageMetadataRef)mutableMetadata
{
    // Copy all the valid tags and ignore the ones that we shouldn't have
    
    CFArrayRef tags = CGImageMetadataCopyTags(metadata);
    for(int i = 0; i < CFArrayGetCount(tags); i++)
    {
        CGImageMetadataTagRef tag = (CGImageMetadataTagRef)CFArrayGetValueAtIndex(tags, i);
        CFStringRef nameSpace = CGImageMetadataTagCopyNamespace(tag);
        CFStringRef prefix = CGImageMetadataTagCopyPrefix(tag);
        CFStringRef name = CGImageMetadataTagCopyName(tag);
        CGImageMetadataType type = CGImageMetadataTagGetType(tag);
        CFTypeRef value = CGImageMetadataTagCopyValue(tag);
        
        if (CFStringCompare(nameSpace, kCGImageMetadataNamespaceExif, 0) == kCFCompareEqualTo ||
            CFStringCompare(nameSpace, kCGImageMetadataNamespaceExifEX, 0) == kCFCompareEqualTo ||
            CFStringCompare(nameSpace, kCGImageMetadataNamespaceExifAux, 0) == kCFCompareEqualTo ||
            CFStringCompare(nameSpace, kCGImageMetadataNamespaceTIFF, 0) == kCFCompareEqualTo ||
            CFStringCompare(nameSpace, kCGImageMetadataNamespaceXMPRights, 0) == kCFCompareEqualTo ||
            CFStringCompare(nameSpace, kCGImageMetadataNamespaceIPTCCore, 0) == kCFCompareEqualTo)
            //CFStringCompare(nameSpace, kCGImageMetadataNamespaceXMPBasic, 0) == kCFCompareEqualTo) // This causes the metadata to no be able to be written to the destination
        {
            NSString* tagPath = [NSString stringWithFormat:@"%@:%@", prefix, name];
            CGImageMetadataTagRef tagValue = CGImageMetadataTagCreate(nameSpace, prefix, name, type, value);
            CGImageMetadataSetTagWithPath(mutableMetadata, NULL, (__bridge CFStringRef)tagPath, tagValue);
            CFRelease(tagValue);
        }
        
        CFRelease(nameSpace);
        CFRelease(prefix);
        CFRelease(name);
        CFRelease(value);
    }
    
    CFRelease(metadata);
    CFRelease(tags);
}

+ (void)addGps:(MAPLocation*)location mutableMetadata:(CGMutableImageMetadataRef)mutableMetadata
{
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
    
    [self addExifMetadata:mutableMetadata tag:@"GPSLatitude"            type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:latitude]];
    [self addExifMetadata:mutableMetadata tag:@"GPSLongitude"           type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:longitude]];
    [self addExifMetadata:mutableMetadata tag:@"GPSLatitudeRef"         type:kCGImageMetadataTypeString value:(__bridge CFStringRef)latitudeRef];
    [self addExifMetadata:mutableMetadata tag:@"GPSLongitudeRef"        type:kCGImageMetadataTypeString value:(__bridge CFStringRef)longitudeRef];
    [self addExifMetadata:mutableMetadata tag:@"GPSTimeStamp"           type:kCGImageMetadataTypeString value:(__bridge CFStringRef)[self getUTCFormattedTime:location.location.timestamp]];
    [self addExifMetadata:mutableMetadata tag:@"GPSDateStamp"           type:kCGImageMetadataTypeString value:(__bridge CFStringRef)[self getUTCFormattedDate:location.location.timestamp]];
    [self addExifMetadata:mutableMetadata tag:@"GPSAltitude"            type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:location.location.altitude]];
    [self addExifMetadata:mutableMetadata tag:@"GPSHPositioningError"   type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:location.location.horizontalAccuracy]];
    [self addExifMetadata:mutableMetadata tag:@"GPSImgDirection"        type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:location.heading.trueHeading]];
    [self addExifMetadata:mutableMetadata tag:@"GPSSpeed"               type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:location.location.speed]];
}

+ (NSString*)getUTCFormattedTime:(NSDate*)localDate
{
    static NSDateFormatter* dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss.SSSSSS";
        
    });
    
    return [dateFormatter stringFromDate:localDate];
}

+ (NSString*)getUTCFormattedDate:(NSDate*)localDate
{
    static NSDateFormatter* dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy:MM:dd";
        
    });
        
    return [dateFormatter stringFromDate:localDate];
}

@end
