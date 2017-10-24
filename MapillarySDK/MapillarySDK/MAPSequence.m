//
//  MAPSequence.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPSequence.h"
#import "MAPUtils.h"
#import "MAPImage.h"
#import "MAPLoginManager.h"
#import "MAPGpxLogger.h"
#import "BOSImageResizeOperation.h"
#import "MAPDefines.h"
#import "MAPGpxParser.h"

static NSString* kGpxLoggerBusy = @"kGpxLoggerBusy";

@interface MAPSequence()

@property MAPGpxLogger* gpxLogger;
@property MAPLocation* currentLocation;
@property dispatch_semaphore_t listLocationsSemaphore;

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
        
        NSString* folderName = [MAPUtils getTimeString:nil];
        self.path = [NSString stringWithFormat:@"%@/%@", [MAPUtils sequenceDirectory], folderName];
        
        [MAPUtils createFolderAtPath:self.path];
        
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
        image.captureDate = [MAPUtils dateFromFilePath:path];
        image.author = author;
        image.location = [self locationForDate:image.captureDate];
        [images addObject:image];
    }
    
    return images;
}
    
- (void)listLocations:(void(^)(NSArray*))done
{
    if (self.gpxLogger.busy)
    {
        self.listLocationsSemaphore = dispatch_semaphore_create(0);
        
        [self.gpxLogger addObserver:self forKeyPath:@"busy" options:0 context:&kGpxLoggerBusy];
        
        dispatch_semaphore_wait(self.listLocationsSemaphore, DISPATCH_TIME_FOREVER);
    }
    
    MAPGpxParser* parser = [[MAPGpxParser alloc] initWithPath:[self.path stringByAppendingPathComponent:@"sequence.gpx"]];
    
    [parser parse:^(NSDictionary *dict) {
        
        NSArray* locations = dict[@"locations"];
        done(locations);
        
    }];
}

- (void)addImageWithData:(NSData*)imageData date:(NSDate*)date location:(MAPLocation*)location
{
    NSAssert(imageData != nil, @"imageData cannot be nil");
    
    if (date == nil)
    {
        date = [NSDate date];        
    }
    
    NSString* fileName = [MAPUtils getTimeString:date];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.jpg", self.path, fileName];
    [imageData writeToFile:fullPath atomically:YES];
    
    NSString* thumbPath = [NSString stringWithFormat:@"%@/%@.jpg", self.path, fileName];
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
        [self.gpxLogger addLocation:location];
        self.currentLocation = location;
    }
}

- (void)addGpx:(NSString*)path
{
    // TODO
}
    
- (MAPLocation*)locationForDate:(NSDate*)date
{
    // TODO
    return nil;
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
