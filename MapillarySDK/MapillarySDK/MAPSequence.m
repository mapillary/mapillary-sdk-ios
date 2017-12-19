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
#import "BOSImageResizeOperation.h"
#import "MAPDefines.h"
#import "MAPGpxParser.h"
#import "MAPUtils.h"

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
    return [self initWithDevice:device andProject:@"Public"];
}

- (id)initWithDevice:(MAPDevice*)device andProject:(NSString*)project
{
    self = [super init];
    if (self)
    {
        self.sequenceDate = [NSDate date];
        self.directionOffset = -1;
        self.timeOffset = 0;
        self.sequenceKey = [[NSUUID UUID] UUIDString];
        self.currentLocation = [[MAPLocation alloc] init];
        self.device = device;
        self.project = project;
        self.cachedLocations = nil;
        
        NSString* folderName = [MAPInternalUtils getTimeString:nil];
        self.path = [NSString stringWithFormat:@"%@/%@", [MAPInternalUtils sequenceDirectory], folderName];
        
        [MAPInternalUtils createFolderAtPath:self.path];
        
        self.gpxLogger = [[MAPGpxLogger alloc] initWithFile:[self.path stringByAppendingPathComponent:@"sequence.gpx"] andSequence:self];
        
    }
    return self;
}

- (NSArray*)listImages
{
    MAPUser* author = [MAPLoginManager currentUser];
    
    NSMutableArray* images = [[NSMutableArray alloc] init];
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    NSArray* extensions = [NSArray arrayWithObjects:@"jpg", @"png", nil];
    NSArray* files = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(pathExtension IN %@)", extensions]];
    
    for (NSString* path in files)
    {
        MAPImage* image = [[MAPImage alloc] init];
        image.imagePath = path;
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

- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date location:(MAPLocation*)location
{
    NSAssert(imageData != nil, @"imageData cannot be nil");
    
    if (date == nil)
    {
        date = [NSDate date];        
    }
    
    NSString* fileName = [MAPInternalUtils getTimeString:date];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.jpg", self.path, fileName];
    [imageData writeToFile:fullPath atomically:YES];
    
    NSString* thumbPath = [NSString stringWithFormat:@"%@/%@-thumb.jpg", self.path, fileName];
    UIImage* srcImage = [UIImage imageWithData:imageData];
    CGSize thumbSize = CGSizeMake(SCREEN_WIDTH/3-1, SCREEN_WIDTH/3-1);
    
    BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:srcImage];
    [op resizeToFitWithinSize:thumbSize];
    op.JPEGcompressionQuality = 0.5;
    [op writeResultToPath:thumbPath];
    [op start];

    if (location)
    {
        [self.gpxLogger addLocation:location];
        self.currentLocation = location;
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
    
- (MAPLocation*)locationForDate:(NSDate*)date
{
    __block MAPLocation* location = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self listLocations:^(NSArray *locations) {

        MAPLocation* first = locations.firstObject;
        MAPLocation* last = locations.lastObject;
        
        // Outside of range, return nil
        if ([date compare:first.timestamp] == NSOrderedDescending || [date compare:last.timestamp] == NSOrderedAscending)
        {
            location = nil;
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
                    exact = currentLocation;
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
                location = [MAPUtils locationBetweenLocationA:before andLocationB:after forDate:date];
            }
            
            // Not possible to interpolate, use the closest position
            else if (before || after)
            {
                location = (before ? before : after);
            }
        }

        dispatch_semaphore_signal(semaphore);
        
    }];
    
    // Wait here intil done
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return [location copy];
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
