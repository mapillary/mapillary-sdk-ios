//
//  GpxLogger.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-03-21.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "GpxLogger.h"
#import "MAPUtils.h"

@interface GpxOperation : NSOperation

@property (nonatomic) NSString* path;
@property (nonatomic) MAPLocation* location;
@property (nonatomic) NSString* time;

@end

@implementation GpxOperation

- (void)main
{
    @autoreleasepool
    {
        NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:self.path];
        
        static const NSString* footer = @"    </trkseg>\n  </trk>\n</gpx>";
        NSData* footerData = [footer dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString* locationString = [NSString stringWithFormat:@"      <trkpt lat=\"%f\" lon=\"%f\"><time>%@</time></trkpt>\n%@", self.location.latitude, self.location.longitude, self.time, footer];
        NSData* locationData = [locationString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
        
        unsigned long long footerLength = footerData.length;
        unsigned long long fileLength = [attributes fileSize];
        
        [file seekToFileOffset:fileLength-footerLength];
        [file writeData:locationData];
        [file closeFile];
    }
}

@end

@interface GpxLogger()

@property (nonatomic) NSOperationQueue* operationQueue;
@property (nonatomic) NSString* path;
@property (nonatomic) NSDateFormatter* dateFormatter;

@end

@implementation GpxLogger

- (id)initWithFile:(NSString*)path
{
    self = [super init];
    
    if (self)
    {
        self.path = path;
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSString* versionString = [MAPUtils appVersion];
            NSString* dateString = [self.dateFormatter stringFromDate:[NSDate date]];
            
            NSString* header = [NSString stringWithFormat:
                                @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n \
                                <gpx version=\"1,0\" creator=\"Mapillary iOS %@ \"\n \
                                xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n \
                                xmlns=\"http://www.topografix.com/GPX/1/0\"\n \
                                xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd\">\n \
                                <time>%@</time>\n \
                                <trk>\n \
                                <trkseg>\n", versionString, dateString];
            
            NSData* data = [header dataUsingEncoding:NSUTF8StringEncoding];
            
            [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
        }
    }
    
    return self;
}

- (void)add:(MAPLocation*)location date:(NSDate*)date
{
    GpxOperation* op = [[GpxOperation alloc] init];
    op.path = self.path;
    op.location = location;
    
    if (date)
    {
        op.time = [self.dateFormatter stringFromDate:date];
    }
    else
    {
        op.time = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    
    [self.operationQueue addOperation:op];
    
    NSLog(@"%lu", (unsigned long)self.operationQueue.operationCount);
}

+ (void)test
{
    NSLog(@"\n\n\n\n");
    
    NSString* path = [NSString stringWithFormat:@"%@/%@", [MAPUtils documentsDirectory], @"test.gpx"];

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    
    GpxLogger* gpx = [[GpxLogger alloc] initWithFile:path];
    
    for (int i = 0; i < 10; i++)
    {
        MAPLocation* l = [[MAPLocation alloc] init];
        l.latitude = 50+(arc4random_uniform(100)/100.0);
        l.longitude = 50+(arc4random_uniform(100)/100.0);
        
        [gpx add:l date:nil];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSString* result = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        NSLog(@"%@\n\n\n\n", result);
        NSLog(@"DONE");
        
    });
}

@end

