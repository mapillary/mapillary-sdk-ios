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
#import "MAPLoginManager.h"
#import "MAPInternalUtils.h"

@implementation MAPExifTools

+ (BOOL)imageHasMapillaryTags:(MAPImage*)image
{
    BOOL ok = NO;
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:image.imagePath], NULL);
    
    if (imageSource)
    {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        NSDictionary* propertiesDictionary = (NSDictionary *)CFBridgingRelease(properties);
        NSDictionary* TIFFDictionary = [propertiesDictionary objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        
        if (TIFFDictionary)
        {
            NSString* description = [TIFFDictionary objectForKey:(NSString *)kCGImagePropertyTIFFImageDescription];
            
            if (description)
            {
                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:[description dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                NSString* MAPLatitude = json[kMAPLatitude];
                NSString* MAPLongitude = json[kMAPLongitude];
                NSString* MAPSettingsUserKey = json[kMAPSettingsUserKey];
                NSString* MAPSettingsUploadHash = json[kMAPSettingsUploadHash];
                
                ok = MAPLatitude && MAPLongitude && MAPSettingsUserKey && MAPSettingsUploadHash;
            }
        }
        
        CFRelease(imageSource);
    }
    
    return ok;
}

+ (BOOL)addExifTagsToImage:(MAPImage*)image fromSequence:(MAPSequence*)sequence
{
    BOOL success = YES;
    
    // Get source and metadata
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:image.imagePath], NULL);
    
    if (imageSource == nil)
    {
        return NO;
    }
    
    CGImageMetadataRef metadata = CGImageSourceCopyMetadataAtIndex(imageSource, 0, NULL);
    CGMutableImageMetadataRef mutableMetadata = CGImageMetadataCreateMutable();
    
    
    // Cleanup existing metadata
    [self cleanMetadata:metadata mutableMetadata:mutableMetadata];
    CFRelease(metadata);
    
    
    // Update and add Mapillary tags to metadata
    NSMutableDictionary* description = [sequence meta];
    description[kMAPLatitude] = [NSNumber numberWithDouble:image.location.location.coordinate.latitude];
    description[kMAPLongitude] = [NSNumber numberWithDouble:image.location.location.coordinate.longitude];
    description[kMAPCaptureTime] = [self getUTCFormattedDateAndTime:image.captureDate];
    description[kMAPGpsTime] = [self getUTCFormattedDateAndTime:image.location.timestamp];
    description[kMAPGPSAccuracyMeters] = [NSNumber numberWithDouble:image.location.location.horizontalAccuracy];
    description[kMAPPhotoUUID] = [[NSUUID UUID] UUIDString];
    description[kMAPAltitude] = [NSNumber numberWithDouble:image.location.location.altitude];
    description[kMAPSettingsUploadHash] = [MAPInternalUtils getSHA256HashFromString:[NSString stringWithFormat:@"%@%@%@",[MAPLoginManager currentUser].accessToken, [MAPLoginManager currentUser].userKey, image.imagePath.lastPathComponent]];
    description[kMAPGPSSpeed] = [NSNumber numberWithDouble:image.location.location.speed];
    
    if (image.location.deviceMotionX != nil && image.location.deviceMotionY != nil && image.location.deviceMotionZ != nil)
    {
        float atanAngle = atan2(image.location.deviceMotionY.doubleValue, image.location.deviceMotionX.doubleValue);
        NSDictionary* accelerometerVector = @{@"x": [NSNumber numberWithDouble:image.location.deviceMotionX.doubleValue],
                                              @"y": [NSNumber numberWithDouble:image.location.deviceMotionY.doubleValue],
                                              @"z": [NSNumber numberWithDouble:image.location.deviceMotionZ.doubleValue]};
        
        description[kMAPAtanAngle] = [NSNumber numberWithDouble:atanAngle];
        description[kMAPAccelerometerVector] = accelerometerVector;
    }
    
    if (image.location.trueHeading != nil && image.location.magneticHeading != nil && image.location.headingAccuracy != nil)
    {
        CLLocationDirection trueHeading = image.location.trueHeading.doubleValue;
        CLLocationDirection magneticHeading = image.location.magneticHeading.doubleValue;
        
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        NSDictionary* propertiesDictionary = (NSDictionary *)CFBridgingRelease(properties);
        NSDictionary* TIFFDictionary = [propertiesDictionary objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        
        if (TIFFDictionary)
        {
            NSNumber* tiffOrientation = TIFFDictionary[@"Orientation"];
            
            // Correct compass with orientation
            if (tiffOrientation.intValue == 1)
            {
                trueHeading += 90;
                magneticHeading += 90;
            }
            else if (tiffOrientation.intValue == 3)
            {
                trueHeading -= 90;
                magneticHeading -= 90;
            }
            else if (tiffOrientation.intValue == 8)
            {
                trueHeading += 180;
                magneticHeading += 180;
            }
            
            trueHeading = fmodf(trueHeading + 360.0f, 360.0f);
            magneticHeading = fmodf(magneticHeading + 360.0f, 360.0f);
            
            image.location.trueHeading = [NSNumber numberWithDouble:trueHeading];
            image.location.magneticHeading = [NSNumber numberWithDouble:magneticHeading];
        }
        
        description[kMAPCompassHeading] = @{kMAPTrueHeading:image.location.trueHeading, kMAPMagneticHeading:image.location.magneticHeading, kMAPAccuracyDegrees:image.location.headingAccuracy};
    }
    
    NSData* descriptionJsonData = [NSJSONSerialization dataWithJSONObject:description options:0 error:nil];
    NSString* descriptionString = [[NSString alloc] initWithData:descriptionJsonData encoding:NSUTF8StringEncoding];
    [self addXmpMetadata:mutableMetadata tag:@"description" type:kCGImageMetadataTypeString value:(__bridge CFStringRef)descriptionString];
    
    
    // Add to default EXIF and TIFF
    [self addGps:image.location mutableMetadata:mutableMetadata];
    
    
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

+ (void)addXmpMetadata:(CGMutableImageMetadataRef)container tag:(NSString*)tag type:(CGImageMetadataType)type value:(CFTypeRef)value
{
    NSString* tagPath = [NSString stringWithFormat:@"%@:%@", @"dc", tag];
    CGImageMetadataTagRef tagValue = CGImageMetadataTagCreate(kCGImageMetadataNamespaceXMPBasic, kCGImageMetadataPrefixXMPBasic, (__bridge CFStringRef)tag, type, value);
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
    
    CFRelease(tags);
}

+ (void)addGps:(MAPLocation*)location mutableMetadata:(CGMutableImageMetadataRef)mutableMetadata
{
    if (location.location)
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
        [self addExifMetadata:mutableMetadata tag:@"GPSDOP"   type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:location.location.horizontalAccuracy]];
        [self addExifMetadata:mutableMetadata tag:@"GPSImgDirection"        type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)location.trueHeading];
        [self addExifMetadata:mutableMetadata tag:@"GPSSpeed"               type:kCGImageMetadataTypeString value:(__bridge CFNumberRef)[NSNumber numberWithDouble:location.location.speed]];
    }
}

+ (NSString*)getUTCFormattedTime:(NSDate*)localDate
{
    static NSDateFormatter* dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss.SSSSSS";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
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
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
    });
        
    return [dateFormatter stringFromDate:localDate];
}

+ (NSString*)getUTCFormattedDateAndTime:(NSDate*)localDate
{
    static NSDateFormatter* dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss_SSS";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
    });
    
    return [dateFormatter stringFromDate:localDate];
}

@end
