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
@property dispatch_semaphore_t listLocationsSemaphore;
@property NSMutableArray* cachedLocations;

@end

@implementation MAPSequence

- (id)initWithDevice:(MAPDevice*)device
{
    return [self initInternal:nil device:device project:nil];
}

- (id)initWithDevice:(MAPDevice*)device andProject:(NSString*)project
{
    return [self initInternal:nil device:device project:project];
}

- (id)initWithPath:(NSString*)path
{
    return [self initInternal:path device:nil project:nil];
}

- (id)initInternal:(NSString*)path device:(MAPDevice*)device project:(NSString*)project
{
    self = [super init];
    if (self)
    {
        self.sequenceDate = [NSDate date];
        self.directionOffset = -1;
        self.timeOffset = 0;
        self.sequenceKey = [[NSUUID UUID] UUIDString];
        self.currentLocation = [[MAPLocation alloc] init];
        self.device = device ? device : [MAPDevice thisDevice];
        self.project = project ? project : @"Public";
        self.cachedLocations = nil;
        self.imageCount = 0;
        self.imageCount = 0;
        
        if (path == nil)
        {
            NSString* folderName = [MAPInternalUtils getTimeString:nil];
            self.path = [NSString stringWithFormat:@"%@/%@", [MAPInternalUtils sequenceDirectory], folderName];
        }
        else
        {
            self.path = path;
            
            NSString* gpxPath = [NSString stringWithFormat:@"%@/sequence.gpx", self.path];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:gpxPath])
            {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:gpxPath];
                
                [parser quickParse:^(NSDictionary *result) {
                    
                    NSNumber* directionOffset = result[@"directionOffset"];
                    NSNumber* timeOffset = result[@"timeOffset"];
                    
                    MAPDevice* device = [[MAPDevice alloc] init];
                    device.make = result[@"deviceMake"];
                    device.model = result[@"deviceModel"];
                    device.UUID = result[@"deviceUUID"];
                    
                    self.sequenceKey = result[@"sequenceKey"];
                    self.sequenceDate = result[@"sequenceDate"];
                    self.directionOffset = directionOffset.doubleValue;
                    self.timeOffset = timeOffset.doubleValue;
                    self.project = result[@"project"];
                    self.device = device;
                    
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
            
            NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
            NSNumber* fileSize = [attrs objectForKey:@"NSFileSize"];
            self.sequenceSize = fileSize.unsignedIntValue;
            
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
    
    // TODO perhaps make configurable
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    float screenHeight = [[UIScreen mainScreen] bounds].size.width;
    CGSize thumbSize = CGSizeMake(screenWidth/3-1, screenHeight/3-1);
    
    // TODO perhaps make optionable
    [MAPInternalUtils createThumbnailForImage:srcImage atPath:thumbPath withSize:thumbSize];

    [self addLocation:location];
    
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

- (NSArray*)listImages
{
    MAPUser* author = [MAPLoginManager currentUser];
    
    NSMutableArray* images = [[NSMutableArray alloc] init];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    NSArray* extensions = [NSArray arrayWithObjects:@"jpg", @"png", nil];
    NSArray* files = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(pathExtension IN %@) AND NOT (self CONTAINS 'thumb')", extensions]];
    
    for (NSString* path in files)
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

- (void)listLocations:(void(^)(NSArray* locations))done
{
    if (self.cachedLocations)
    {
        done(self.cachedLocations);
        return;
    }
    
    if (self.gpxLogger.busy)
    {
        self.listLocationsSemaphore = dispatch_semaphore_create(0);
        
        [self.gpxLogger addObserver:self forKeyPath:@"busy" options:0 context:&kGpxLoggerBusy];
        
        dispatch_semaphore_wait(self.listLocationsSemaphore, DISPATCH_TIME_FOREVER);
    }
    
    dispatch_queue_t reentrantAvoidanceQueue = dispatch_queue_create("reentrantAvoidanceQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(reentrantAvoidanceQueue, ^{
        
        MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:[self.path stringByAppendingPathComponent:@"sequence.gpx"]];
        
        [parser parse:^(NSDictionary *dict) {
            
            NSArray* locations = dict[@"locations"];
            
            NSArray* sorted = [locations sortedArrayUsingComparator:^NSComparisonResult(MAPLocation* a, MAPLocation* b) {
                return [b.timestamp compare:a.timestamp];
            }];
            
            self.cachedLocations = [[NSMutableArray alloc] initWithArray:sorted];
            
            done(sorted);
            
        }];
        
    });
    dispatch_sync(reentrantAvoidanceQueue, ^{ });
}
    
- (MAPLocation*)locationForDate:(NSDate*)date
{
    // TODO handle compass direction
    
    __block MAPLocation* location = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self listLocations:^(NSArray *locations) {

        MAPLocation* first = locations.firstObject;
        MAPLocation* last = locations.lastObject;
        
        // Outside of range, clamp
        if ([date compare:first.timestamp] == NSOrderedDescending || [date compare:last.timestamp] == NSOrderedAscending)
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
            MAPLocation* exact = nil;
            MAPLocation* after = nil;
            
            int i = 0;
            
            while ((exact == nil ||  after == nil || before == nil) && i < locations.count)
            {
                MAPLocation* currentLocation = locations[i];
                
                if ([currentLocation.timestamp isEqualToDate:date])
                {
                    if (i < locations.count-1)
                    {
                        before = locations[i+1];
                    }
                    else
                    {
                        before = currentLocation;
                    }
                    
                    exact = currentLocation;
                    
                    if (i > 0)
                    {
                        after = locations[i-1];
                    }
                    else
                    {
                        after = currentLocation;
                    }
                }
                
                else if ([currentLocation.timestamp compare:date] == NSOrderedAscending)
                {
                    if (i > 0)
                    {
                        after = locations[i-1];
                    }
                    
                    before = currentLocation;
                }
                
                i++;
            }
            
            // Exact match
            if (exact)
            {
                location = exact;
            }
            
            // No match found, need to interpolate between two positions
            else if (before && after)
            {
                location = [MAPInternalUtils locationBetweenLocationA:before andLocationB:after forDate:date];
            }
            
            // Not possible to interpolate, use the closest position
            else if (before || after)
            {
                location = (before ? before : after);
            }
            
            location.magneticHeading = [MAPInternalUtils calculateHeadingFromCoordA:before.location.coordinate B:after.location.coordinate];
            location.trueHeading = location.magneticHeading;
        }

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

#pragma mark - Internal

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.gpxLogger && [keyPath isEqualToString:@"busy"] && context == &kGpxLoggerBusy)
    {
        if (!self.gpxLogger.busy)
        {            
            [self.gpxLogger removeObserver:self forKeyPath:@"busy" context:&kGpxLoggerBusy];
            dispatch_semaphore_signal(self.listLocationsSemaphore);
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
