//
//  MAPSequence.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPSequence.h"
#import "MAPInternalUtils.h"
#import "MAPImage.h"
#import "MAPLoginManager.h"
#import "MAPGpxLogger.h"
#import "MAPDefines.h"
#import "MAPGpxParser.h"
#import "MAPUtils.h"
#import "MAPImage+Private.h"
#import "MAPExifTools.h"

static NSString* kGpxLoggerBusy = @"kGpxLoggerBusy";

@interface MAPSequence()

@property MAPGpxLogger* gpxLogger;
@property MAPLocation* currentLocation;
@property dispatch_semaphore_t getLocationsSemaphore;
@property NSMutableArray* cachedLocations;

@end

@implementation MAPSequence

- (id)init
{
    return [self initInternal:nil device:nil project:nil parseGpx:NO];
}

- (id)initWithDevice:(MAPDevice*)device
{
    return [self initInternal:nil device:device project:nil parseGpx:NO];
}

- (id)initWithDevice:(MAPDevice*)device andProject:(NSString*)project
{
    return [self initInternal:nil device:device project:project parseGpx:NO];
}

- (id)initWithPath:(NSString*)path parseGpx:(BOOL)parseGpx
{
    return [self initInternal:path device:nil project:nil parseGpx:parseGpx];
}

- (id)initInternal:(NSString*)path device:(MAPDevice*)device project:(NSString*)project parseGpx:(BOOL)parseGpx
{
    self = [super init];
    if (self)
    {
        self.sequenceDate = [NSDate date];
        self.directionOffset = nil;
        self.timeOffset = nil;
        self.sequenceKey = [[NSUUID UUID] UUIDString];
        self.currentLocation = [[MAPLocation alloc] init];
        self.device = device ? device : [MAPDevice thisDevice];
        self.organizationKey = nil;
        self.private = NO;
        self.cachedLocations = nil;
        self.imageCount = 0;
        self.imageOrientation = 0;
        
        if (path == nil)
        {
            NSString* folderName = [MAPInternalUtils getTimeString:nil];
            self.path = [NSString stringWithFormat:@"%@/%@", [MAPInternalUtils sequenceDirectory], folderName];
        }
        else
        {
            self.path = path;
            
            NSString* gpxPath = [NSString stringWithFormat:@"%@/sequence.gpx", self.path];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:gpxPath] && parseGpx)
            {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:gpxPath];
                
                [parser quickParse:^(NSDictionary *result) {
                    
                    NSNumber* private = result[kMAPPrivate];
                    
                    MAPDevice* device = [[MAPDevice alloc] init];
                    device.make = result[kMAPDeviceMake];
                    device.model = result[kMAPDeviceModel];
                    device.UUID = result[kMAPDeviceUUID];
                    
                    self.sequenceKey = result[kMAPSequenceUUID];
                    self.sequenceDate = result[kMAPCaptureTime];
                    self.directionOffset = result[kMAPDirectionOffset];
                    self.timeOffset = result[kMAPTimeOffset];
                    self.organizationKey = result[kMAPOrganizationKey];
                    self.private = private.boolValue;
                    self.device = device;
                    self.imageOrientation = result[kMAPOrientation];
                    self.rigSequenceUUID = result[kMAPRigSequenceUUID];
                    self.rigUUID = result[kMAPRigUUID];
                    
                    dispatch_semaphore_signal(semaphore);
                    
                }];
                
                // Wait here intil done
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.path])
        {
            NSArray* dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
            
            NSPredicate* fltr = [NSPredicate predicateWithFormat:@"(self ENDSWITH '.jpg') AND NOT (self CONTAINS 'thumb')"];
            NSArray* dirContentsFiltered = [dirContents filteredArrayUsingPredicate:fltr];
            self.imageCount = dirContentsFiltered.count;
            
            if ([dirContentsFiltered count] > 0)
            {
                // Image count,
                self.imageCount = dirContentsFiltered.count;
                
                // Sequence size
                for (NSString* f in dirContentsFiltered)
                {
                    NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.path stringByAppendingPathComponent:f] error:nil];
                    NSNumber* fileSize = [attrs objectForKey:@"NSFileSize"];
                    self.sequenceSize += fileSize.unsignedIntegerValue;
                }
            }
        }
        else
        {
            [MAPInternalUtils createFolderAtPath:self.path];
        }
        
        self.gpxLogger = [[MAPGpxLogger alloc] initWithFile:[self.path stringByAppendingPathComponent:@"sequence.gpx"] andSequence:self];
    }
    
    return self;
}

- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date location:(MAPLocation*)location
{
    if (imageData == nil)
    {
        return;
    }
    
    if (date == nil)
    {
        date = [NSDate date];        
    }
    
    NSString* fileName = [MAPInternalUtils getTimeString:date];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.jpg", self.path, fileName];
    [imageData writeToFile:fullPath atomically:YES];
    
    NSString* thumbPath = [NSString stringWithFormat:@"%@/%@-thumb.jpg", self.path, fileName];
    UIImage* srcImage = [UIImage imageWithData:imageData];
    
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    float screenHeight = [[UIScreen mainScreen] bounds].size.width;
    CGSize thumbSize = CGSizeMake(screenWidth/3-1, screenHeight/3-1);
    
    [MAPInternalUtils createThumbnailForImage:srcImage atPath:thumbPath withSize:thumbSize];
    
    [self addLocation:location];
    
    self.imageCount++;
    self.sequenceSize += imageData.length;
    
    if (self.imageOrientation == nil)
    {
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)(imageData), NULL);
        if (source)
        {
            CFDictionaryRef cfDict = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
            NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(cfDict);
            NSDictionary* TIFFDictionary = [metadata objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
            
            if (TIFFDictionary)
            {
                NSNumber* tiffOrientation = TIFFDictionary[@"Orientation"];
                
                if (tiffOrientation && self.imageOrientation.intValue != tiffOrientation.intValue)
                {
                    self.imageOrientation = tiffOrientation;
                    [self savePropertyChanges:nil];
                }
            }
            
            CFRelease(source);
        }
    }
}

- (void)addImageWithPath:(NSString*)imagePath date:(NSDate*)date location:(MAPLocation*)location
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
    {
        NSData* data = [NSData dataWithContentsOfFile:imagePath];
        
        if (data)
        {
            [self addImageWithData:data date:date location:location];
        }
    }
}

- (void)addLocation:(MAPLocation*)location
{
    if (location)
    {
        if (self.cachedLocations)
        {
            [self.cachedLocations addObject:[location copy]];
        }
        
        [self.gpxLogger addLocation:location];
        self.currentLocation = location;
    }
}

- (void)addGpx:(NSString*)path done:(void(^)(void))done
{
    if (path == nil || ![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        if (done)
        {
            done();
        }
        return;
    }
    
    MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:path];
    [parser parse:^(NSDictionary *dict) {
        
        NSArray* locations = dict[@"locations"];
        
        for (MAPLocation* l in locations)
        {
            [self addLocation:l];
        }
        
        if (done)
        {
            done();
        }
    }];    
}

- (void)processImage:(MAPImage*)image
{
    [MAPExifTools addExifTagsToImage:image fromSequence:self];
}

- (void)deleteImage:(MAPImage*)image
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:image.imagePath])
    {
        // Update stats
        NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:image.imagePath error:nil];
        NSNumber* fileSize = [attrs objectForKey:@"NSFileSize"];
        self.sequenceSize -= fileSize.unsignedIntValue;
        self.imageCount--;
        
        // Delete files
        [image delete];        
    }
}

- (void)deleteAllImages
{
    for (MAPImage* image in [self getImages])
    {
        [self deleteImage:image];
    }
}

- (NSArray*)getImages
{
    MAPUser* author = [MAPLoginManager currentUser];
    
    NSMutableArray* images = [[NSMutableArray alloc] init];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    NSArray* extensions = [NSArray arrayWithObjects:@"jpg", @"png", nil];
    NSArray* files = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(pathExtension IN %@) AND NOT (self CONTAINS 'thumb')", extensions]];
    NSArray* sortedFiles = [files sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (NSString* path in sortedFiles)
    {
        MAPImage* image = [[MAPImage alloc] init];
        image.imagePath = [self.path stringByAppendingPathComponent:path];
        image.captureDate = [MAPInternalUtils dateFromFilePath:path];
        image.author = author;
        image.location = [self locationForDate:image.captureDate];
        
        [images addObject:image];
    }
    
    return images;
}

- (void)getImagesAsync:(void(^)(NSArray* images))result
{
    if (result)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSArray* images = [self getImages];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                result(images);
                
            });
            
        });
    }
}

- (void)getLocationsAsync:(void(^)(NSArray* locations))done
{
    if (self.cachedLocations)
    {
        done(self.cachedLocations);
        return;
    }
    
    if (self.gpxLogger.busy)
    {
        self.getLocationsSemaphore = dispatch_semaphore_create(0);
        
        [self.gpxLogger addObserver:self forKeyPath:@"busy" options:0 context:&kGpxLoggerBusy];
        
        dispatch_semaphore_wait(self.getLocationsSemaphore, DISPATCH_TIME_FOREVER);
    }
    
    dispatch_queue_t reentrantAvoidanceQueue = dispatch_queue_create("reentrantAvoidanceQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(reentrantAvoidanceQueue, ^{
        
        MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:[self.path stringByAppendingPathComponent:@"sequence.gpx"]];
        
        [parser parse:^(NSDictionary *dict) {
            
            NSArray* locations = dict[@"locations"];
            
            NSArray* sorted = [locations sortedArrayUsingComparator:^NSComparisonResult(MAPLocation* a, MAPLocation* b) {
                return [a.timestamp compare:b.timestamp];
            }];
            
            self.cachedLocations = [[NSMutableArray alloc] initWithArray:sorted];            
            
            done(sorted);
            
        }];
        
    });
    dispatch_sync(reentrantAvoidanceQueue, ^{ });
}
    
- (MAPLocation*)locationForDate:(NSDate*)date
{
    if (date == nil)
    {
        return nil;
    }
    
    __block MAPLocation* location = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self getLocationsAsync:^(NSArray *locations) {

        MAPLocation* first = locations.firstObject;
        MAPLocation* last = locations.lastObject;
        
        // Outside of range, clamp
        if ([date compare:first.timestamp] == NSOrderedAscending || [date compare:last.timestamp] == NSOrderedDescending)
        {
            NSTimeInterval diff1 = [date timeIntervalSinceDate:first.timestamp];
            NSTimeInterval diff2 = [date timeIntervalSinceDate:last.timestamp];
            
            if (fabs(diff1) < fabs(diff2))
            {
                location = first;
            }
            else
            {
                location = last;
            }
            
            location.magneticHeading = [MAPInternalUtils calculateHeadingFromCoordA:first.location.coordinate B:last.location.coordinate];
            location.trueHeading = location.magneticHeading;
        }
        
        // Find position
        else
        {
            MAPLocation* before = nil;
            MAPLocation* equal = nil;
            MAPLocation* after = nil;
            
            for (int i = 0; i < locations.count; i++)
            {
                MAPLocation* currentLocation = locations[i];
                
                if ([currentLocation.timestamp compare:date] == NSOrderedSame)
                {
                    equal = currentLocation;
                }
                
                else if ([currentLocation.timestamp compare:date] == NSOrderedDescending)
                {
                    if (i > 0)
                    {
                        before = locations[i-1];
                    }
                    
                    after = currentLocation;
                    
                    break;
                }
            }
            
            // Found a match
            if (equal)
            {
                location = equal;
                
                if (after)
                {
                    location.magneticHeading = [MAPInternalUtils calculateHeadingFromCoordA:equal.location.coordinate B:after.location.coordinate];
                    location.trueHeading = location.magneticHeading;
                }
            }
            
            // Need to interpolate between two positions
            else if (before && after)
            {
                location = [MAPInternalUtils locationBetweenLocationA:before andLocationB:after forDate:date];
            }
            
            // Only found one, not possible to interpolate, use the one position we found
            else if (before || after)
            {
                location = (before ? before : after);
            }
            
            // None found, not possible to interpolate, use the one position available
            else
            {
                location = locations.firstObject;
            }
        }
        
        float trueHeading = location.trueHeading.floatValue;
        float magneticHeading = location.magneticHeading.floatValue;
        
        if (self.imageOrientation != nil)
        {
            switch (self.imageOrientation.intValue)
            {
                case 1:
                    trueHeading += 90;
                    magneticHeading += 90;
                    break;
                    
                case 3:
                    trueHeading -= 90;
                    magneticHeading -= 90;
                    break;
                    
                case 8:
                    trueHeading += 180;
                    magneticHeading += 180;
                    break;
                    
                default:
                    break;
            }
        }
        
        if (self.directionOffset != nil)
        {
            trueHeading += self.directionOffset.floatValue;
            magneticHeading += self.directionOffset.floatValue;
        }
        
        trueHeading = fmodf(trueHeading + 360.0f, 360.0f);
        magneticHeading = fmodf(magneticHeading + 360.0f, 360.0f);
        
        location.trueHeading = [NSNumber numberWithFloat:trueHeading];
        location.magneticHeading = [NSNumber numberWithFloat:magneticHeading];

        dispatch_semaphore_signal(semaphore);
        
    }];
    
    // Wait here intil done
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return location;
}

- (BOOL)isLocked
{
    NSString* path = [self.path stringByAppendingPathComponent:@"lock"];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)savePropertyChanges:(void(^)(void))done
{
    NSString* gpxPath = [NSString stringWithFormat:@"%@/sequence.gpx", self.path];
    NSString* gpxPathBackup = [NSString stringWithFormat:@"%@/sequence.bak", self.path];

    [self getLocationsAsync:^(NSArray *locations) {
        
        // Move old file
        [[NSFileManager defaultManager] moveItemAtPath:gpxPath toPath:gpxPathBackup error:nil];
        
        // Create new file
        self.gpxLogger = [[MAPGpxLogger alloc] initWithFile:gpxPath andSequence:self];
        
        for (MAPLocation* l in locations)
        {
            [self.gpxLogger addLocation:l];
        }
        
        // TODO check that everything is ok
        
        // Delete old file
        [[NSFileManager defaultManager] removeItemAtPath:gpxPathBackup error:nil];
        
        if (done)
        {
            done();
        }
        
    }];
}

- (MAPImage*)getPreviewImage
{
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    NSArray* extensions = [NSArray arrayWithObjects:@"jpg", @"png", nil];
    NSArray* files = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(pathExtension IN %@) AND NOT (self CONTAINS 'thumb')", extensions]];
    
    NSString* path = files.firstObject;
    
    MAPImage* image = [[MAPImage alloc] init];
    image.imagePath = [self.path stringByAppendingPathComponent:path];
    image.captureDate = [MAPInternalUtils dateFromFilePath:path];
    image.author = [MAPLoginManager currentUser];
    image.location = nil;

    return image;
}

#pragma mark - Internal

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.gpxLogger && [keyPath isEqualToString:@"busy"] && context == &kGpxLoggerBusy)
    {
        if (!self.gpxLogger.busy)
        {            
            [self.gpxLogger removeObserver:self forKeyPath:@"busy" context:&kGpxLoggerBusy];
            dispatch_semaphore_signal(self.getLocationsSemaphore);
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
