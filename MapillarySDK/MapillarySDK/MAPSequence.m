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
#import "MAPDataManager.h"
#import "MAPApiManager.h"

static NSString* kGpxLoggerBusy = @"kGpxLoggerBusy";

@interface MAPSequence()

@property MAPGpxLogger* gpxLogger;
@property MAPLocation* currentLocation;
@property dispatch_semaphore_t getLocationsSemaphore;
@property NSMutableArray* cachedLocations;

@end

@implementation MAPSequence

/*- (id)init
{
    return [self initInternal:nil device:nil date:nil parseGpx:NO];
}*/

- (id)initWithDevice:(MAPDevice*)device
{
    return [self initInternal:nil device:device date:nil parseGpx:NO];
}

- (id)initWithDevice:(MAPDevice*)device andDate:(NSDate*)date
{
    return [self initInternal:nil device:device date:date parseGpx:NO];
}

- (id)initWithPath:(NSString*)path parseGpx:(BOOL)parseGpx
{
    return [self initInternal:path device:nil date:nil parseGpx:parseGpx];
}

- (id)initInternal:(NSString*)path device:(MAPDevice*)device date:(NSDate*)date parseGpx:(BOOL)parseGpx
{
    self = [super init];
    if (self)
    {
        if (date == nil && path != nil)
        {
            date = [MAPInternalUtils dateFromFilePath:path];
        }
        
        if (date == nil)
        {
            date = [NSDate date];
        }
        
        self.sequenceDate = date;
        self.directionOffset = nil;
        self.timeOffset = nil;
        self.sequenceKey = [[NSUUID UUID] UUIDString];
        self.currentLocation = nil;
        self.device = device;
        self.organizationKey = nil;
        self.isPrivate = NO;
        self.cachedLocations = nil;
        self.imageCount = 0;
        
        if (path == nil)
        {
            NSString* folderName = [MAPInternalUtils getTimeString:date];
            self.path = [NSString stringWithFormat:@"%@/%@", [MAPInternalUtils sequenceDirectory], folderName];
            self.gpxPath = [NSString stringWithFormat:@"%@/sequence.gpx", self.path];
        }
        else
        {
            self.path = path;
            self.gpxPath = [NSString stringWithFormat:@"%@/sequence.gpx", self.path];
            
            if ([self hasGpxFile] && parseGpx)
            {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:self.gpxPath];
                
                [parser quickParse:^(NSDictionary *result) {
                    
                    NSNumber* isPrivate = result[kMAPPrivate];
                    
                    MAPDevice* device = [[MAPDevice alloc] init];
                    device.make = result[kMAPDeviceMake];
                    device.model = result[kMAPDeviceModel];
                    device.UUID = result[kMAPDeviceUUID];
                    device.isExternal = ![device.make isEqualToString:@"Apple"];
                    
                    self.sequenceKey = result[kMAPSequenceUUID];
                    self.sequenceDate = result[kMAPCaptureTime];
                    self.directionOffset = result[kMAPDirectionOffset];
                    self.timeOffset = result[kMAPTimeOffset];
                    self.organizationKey = result[kMAPOrganizationKey];
                    self.isPrivate = isPrivate.boolValue;
                    self.device = device;
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
        
        if (self.device && !self.device.isExternal)
        {
            self.gpxLogger = [[MAPGpxLogger alloc] initWithFile:self.gpxPath andSequence:self];
        }
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
    
    if (location.timestamp == nil)
    {
        location.timestamp = date;
    }
    
    // Save image
    NSString* fileName = [MAPInternalUtils getTimeString:date];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.jpg", self.path, fileName];
    [imageData writeToFile:fullPath atomically:YES];
    
    // If location is provided, add EXIF here
    if (location && (self.directionOffset == nil || (self.directionOffset != nil && self.currentLocation)))
    {
        NSLog(@"Adding EXIF to image");
        
        MAPImage* image = [[MAPImage alloc] initWithPath:fullPath];
        image.location = location;
        
        // If we are not using the compass for the heading (directionOffset == nil), we need to calcuate the heading from the previous image
        if (self.directionOffset != nil)
        {
            double calculatedHeading = [MAPInternalUtils calculateHeadingFromCoordA:self.currentLocation.location.coordinate B:location.location.coordinate].doubleValue;
            
            if (fabs(self.directionOffset.doubleValue) > 0.0)
            {
                calculatedHeading += self.directionOffset.doubleValue;
                calculatedHeading = fmodf(calculatedHeading + 360.0f, 360.0f);
            }
            
            image.location.trueHeading = [NSNumber numberWithDouble:calculatedHeading];
            image.location.magneticHeading = [NSNumber numberWithDouble:calculatedHeading];
            image.location.headingAccuracy = @0;
        }
        
        BOOL sucess = [MAPExifTools addExifTagsToImage:image fromSequence:self];
        if (sucess)
        {
            [[MAPDataManager sharedManager] setImageAsProcessed:image];
        }
    }
    else
    {
        // Create thumbnail
        NSString* thumbPath = [NSString stringWithFormat:@"%@/%@-thumb.jpg", self.path, fileName];
        UIImage* srcImage = [UIImage imageWithData:imageData];
        
        float screenWidth = [[UIScreen mainScreen] bounds].size.width;
        float screenHeight = [[UIScreen mainScreen] bounds].size.width;
        CGSize thumbSize = CGSizeMake(screenWidth/3-1, screenHeight/3-1);
        
        [MAPInternalUtils createThumbnailForImage:srcImage atPath:thumbPath withSize:thumbSize];
    }

    // Add location to GPX
    [self addLocation:location];
    
    // Update stats
    self.imageCount++;
    self.sequenceSize += imageData.length;
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
    // Sanity check that coordinate is valid
    if (location &&
        CLLocationCoordinate2DIsValid(location.location.coordinate) &&
        fabs(location.location.coordinate.latitude) > DBL_EPSILON &&
        fabs(location.location.coordinate.longitude) > DBL_EPSILON)
    {
        
        // Skip duplicates. It would be too slow to check all coordinates so here we just compare to the previous coordinate
        if (self.currentLocation &&
            fabs(self.currentLocation.location.coordinate.latitude-location.location.coordinate.latitude) < 0.000001 && // > 10 cm
            fabs(self.currentLocation.location.coordinate.longitude-location.location.coordinate.longitude) < 0.000001 && // > 10 cm
            fabs(self.currentLocation.location.course-location.location.course) < 1) // 1 deg
        {
            return;
        }
        
        if (self.device.isExternal)
        {
            [[MAPDataManager sharedManager] addLocation:location sequence:self];
        }
        else
        {
            if (self.cachedLocations)
            {
                [self.cachedLocations addObject:[location copy]];
            }
            
            [self.gpxLogger addLocation:location];
        }
        
        self.currentLocation = [location copy];
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

- (void)processImage:(MAPImage*)image forceReprocessing:(BOOL)forceReprocessing
{
    if (forceReprocessing || ![[MAPDataManager sharedManager] isImageProcessed:image] || ![MAPExifTools imageHasMapillaryTags:image])
    {
        BOOL success = [MAPExifTools addExifTagsToImage:image fromSequence:self];
        if (success)
        {
            [[MAPDataManager sharedManager] setImageAsProcessed:image];
        }        
    }
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
    // Delete upload session
    MAPUploadSession* uploadSession = [[MAPDataManager sharedManager] getUploadSessionForSequenceKey:self.sequenceKey];
    
    if (uploadSession != nil)
    {
        NSLog(@"CLOSING SESSION");
        [MAPApiManager endUploadSession:uploadSession.uploadSessionKey done:^(BOOL success) {
            
        }];
    }
    
    NSMutableArray* images = [[NSMutableArray alloc] init];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    NSArray* extensions = [NSArray arrayWithObjects:@"jpg", @"png", nil];
    NSArray* files = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(pathExtension IN %@) AND NOT (self CONTAINS 'thumb')", extensions]];
    
    for (NSString* path in files)
    {
        MAPImage* image = [[MAPImage alloc] init];
        image.imagePath = [self.path stringByAppendingPathComponent:path];
        [images addObject:image];
    }
    
    for (MAPImage* image in images)
    {
        [self deleteImage:image];
    }
}

- (NSArray*)getImages
{
    MAPUser* author = [MAPLoginManager currentUser];
    
    NSMutableArray* images = [[NSMutableArray alloc] init];
    NSArray* imagePaths = [self getImagePaths];
    
    for (NSString* path in imagePaths)
    {
        MAPImage* image = [[MAPImage alloc] init];
        image.imagePath = path;
        image.captureDate = [MAPInternalUtils dateFromFilePath:path.lastPathComponent];
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

- (NSArray*)getImagePaths
{
    
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    NSArray* extensions = [NSArray arrayWithObjects:@"jpg", @"png", nil];
    NSArray* files = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(pathExtension IN %@) AND NOT (self CONTAINS 'thumb')", extensions]];
    NSArray* sortedFiles = [files sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSMutableArray* fullPathsArray = [NSMutableArray arrayWithCapacity:sortedFiles.count];
    
    for (NSString* path in sortedFiles)
    {
        NSString* fullPath = [self.path stringByAppendingPathComponent:path];
        [fullPathsArray addObject:fullPath];
    }
    
    return fullPathsArray;
}

- (void)getLocationsAsync:(void(^)(NSArray* locations))done
{
    if (self.device.isExternal || ![self hasGpxFile] || self.device == nil)
    {
        // Try to get locations limited to the external device first
        [[MAPDataManager sharedManager] getAllLocationsLimitedToDevice:self.device result:^(NSArray *locations, MAPDevice *device, NSString *organizationKey, bool isPrivate) {
            
            // If we get 0 locations, it could be due to the camera ID has changed, so get all loctions as a fallback
            if (locations.count == 0)
            {
                [[MAPDataManager sharedManager] getAllLocationsLimitedToDevice:nil result:^(NSArray *locations, MAPDevice *device, NSString *organizationKey, bool isPrivate) {
                    
                    done(locations);
                    
                }];
            }
            else
            {
                done(locations);
            }
        }];
    }
    else
    {
        if (self.cachedLocations)
        {
            done([[NSArray alloc] initWithArray:self.cachedLocations copyItems:YES]);
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
            
            MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:self.gpxPath];
            
            [parser parse:^(NSDictionary *dict) {
                
                NSArray* locations = dict[@"locations"];
                
                NSArray* sorted = [locations sortedArrayUsingComparator:^NSComparisonResult(MAPLocation* a, MAPLocation* b) {
                    return [a.timestamp compare:b.timestamp];
                }];
                
                self.cachedLocations = [[NSMutableArray alloc] initWithArray:sorted];
                
                done([[NSArray alloc] initWithArray:self.cachedLocations copyItems:YES]);
                
            }];
            
        });
        dispatch_sync(reentrantAvoidanceQueue, ^{ });
    }
}
    
- (MAPLocation*)locationForDate:(NSDate*)date
{
    if (date == nil)
    {
        return nil;
    }
    
    if (self.timeOffset != nil)
    {
        date = [date dateByAddingTimeInterval:self.timeOffset.doubleValue];
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
            
            MAPLocation* A = nil;
            MAPLocation* B = nil;
            
            if (fabs(diff1) < fabs(diff2))
            {
                A = first;
                location = first;
                
                if (locations.count > 1)
                {
                    B = locations[1];
                }
            }
            else
            {
                B = last;
                location = last;
                
                if (locations.count > 1)
                {
                    A = locations[locations.count-2];
                }
            }
            
            if (location.magneticHeading == nil || location.trueHeading == nil || (self.directionOffset != nil && self.directionOffset.intValue == 0))
            {
                location.magneticHeading = [MAPInternalUtils calculateHeadingFromCoordA:A.location.coordinate B:B.location.coordinate];
                location.trueHeading = location.magneticHeading;
                location.headingAccuracy = @0;
            }
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
                    if (i > 0)
                    {
                        before = locations[i-1];
                    }
                    
                    equal = currentLocation;
                    
                    if (i+1 < locations.count)
                    {
                        after = locations[i+1];
                    }
                    
                    break;
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
                
                if (location.magneticHeading == nil || location.trueHeading == nil || (self.directionOffset != nil && self.directionOffset.intValue == 0))
                {
                    if (after)
                    {
                        location.magneticHeading = [MAPInternalUtils calculateHeadingFromCoordA:equal.location.coordinate B:after.location.coordinate];
                        location.trueHeading = location.magneticHeading;
                        location.headingAccuracy = @0;
                    }                    
                    else if (before)
                    {
                        location.magneticHeading = [MAPInternalUtils calculateHeadingFromCoordA:before.location.coordinate B:equal.location.coordinate];
                        location.trueHeading = location.magneticHeading;
                        location.headingAccuracy = @0;
                    }
                }
            }
            
            // Need to interpolate between two positions
            else if (before && after)
            {
                location = [MAPInternalUtils locationBetweenLocationA:before andLocationB:after forDate:date];
                
                if (location.magneticHeading == nil || location.trueHeading == nil || (self.directionOffset != nil && self.directionOffset.intValue == 0))
                {
                    location.magneticHeading = [MAPInternalUtils calculateHeadingFromCoordA:before.location.coordinate B:after.location.coordinate];
                    location.trueHeading = location.magneticHeading;
                    location.headingAccuracy = @0;
                }
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
        
        double trueHeading = location.trueHeading.doubleValue;
        double magneticHeading = location.magneticHeading.doubleValue;
        
        if (self.directionOffset != nil && fabs(self.directionOffset.doubleValue) > 0.0)
        {
            trueHeading += self.directionOffset.doubleValue;
            magneticHeading += self.directionOffset.doubleValue;
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
    if ((self.device.isExternal && self.timeOffset != nil) || ![self hasGpxFile])
    {
        NSArray* images = [self getImages];
        MAPImage* first = images.firstObject;
        MAPImage* last = images.lastObject;
        NSDate* from = [first.captureDate dateByAddingTimeInterval:self.timeOffset.doubleValue];
        NSDate* to = [last.captureDate dateByAddingTimeInterval:self.timeOffset.doubleValue];
        
        [[MAPDataManager sharedManager] getLocationsFrom:from to:to limitedToDevice:self.device result:^(NSArray *locations, MAPDevice *device, NSString *organizationKey, bool isPrivate) {
            
            self.device = device;
            self.organizationKey = organizationKey;
            self.isPrivate = isPrivate;
        
            [self createGpx:locations];
            
            if (done)
            {
                done();
            }
        }];
    }
    else
    {
        __block NSArray* existingLocations = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [self getLocationsAsync:^(NSArray *locations) {
            
            existingLocations = locations;
            
            dispatch_semaphore_signal(semaphore);
            
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        [self createGpx:existingLocations];
        
        if (done)
        {
            done();
        }
    }
}

- (BOOL)hasGpxFile
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.gpxPath];
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

- (void)createGpx:(NSArray*)locations
{
    NSString* gpxPathBackup = [NSString stringWithFormat:@"%@/sequence.bak", self.path];
    
    // Move old file
    [[NSFileManager defaultManager] moveItemAtPath:self.gpxPath toPath:gpxPathBackup error:nil];
    
    // Create new file
    self.gpxLogger = [[MAPGpxLogger alloc] initWithFile:self.gpxPath andSequence:self];
    
    for (MAPLocation* l in locations)
    {
        [self.gpxLogger addLocation:l];
    }
    
    // TODO check that everything is ok
    
    // Delete old file
    [[NSFileManager defaultManager] removeItemAtPath:gpxPathBackup error:nil];
}

@end
