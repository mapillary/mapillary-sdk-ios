//
//  MAPGpxLogger.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-03-21.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPGpxLogger.h"
#import "MAPInternalUtils.h"
#import "MAPLoginManager.h"

static NSString* kQueueOperationsChanged = @"kQueueOperationsChanged";

@interface MAPGpxOperation : NSOperation

@property (nonatomic) NSString* path;
@property (nonatomic) MAPLocation* location;
@property (nonatomic) NSString* time;

@end

NSString* footer;
unsigned long long footerLength;

@implementation MAPGpxOperation

- (void)main
{
    @autoreleasepool
    {
        NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:self.path];
        NSMutableString* locationString = [[NSMutableString alloc] init];
        
        // Add location
        [locationString appendFormat:@"\t\t\t<trkpt lat=\"%f\" lon=\"%f\">\n", self.location.location.coordinate.latitude, self.location.location.coordinate.longitude];
        
        // Add eleveation if available
        if (self.location.location.verticalAccuracy > 0)
        {
            [locationString appendFormat:@"\t\t\t\t<ele>%f</ele>\n", self.location.location.altitude];
        }
        
        // Add time
        [locationString appendFormat:@"\t\t\t\t<time>%@</time>\n", self.time];
        
        // Add fix
        if (self.location.location.verticalAccuracy > 0)
        {
            [locationString appendString:@"\t\t\t\t<fix>3d</fix>\n"];
        }
        else
        {
            [locationString appendString:@"\t\t\t\t<fix>2d</fix>\n"];
        }
        
        // Add exgtensions
        NSMutableString* extensionsString = [[NSMutableString alloc] init];
        [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:gpsAccuracyMeters>%f</mapillary:gpsAccuracyMeters>\n", self.location.location.horizontalAccuracy];
        
        if (self.location.heading)
        {
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:compassTrueHeading>%f</mapillary:compassTrueHeading>\n", self.location.heading.trueHeading];
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:compassMagneticHeading>%f</mapillary:compassMagneticHeading>\n", self.location.heading.magneticHeading];
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:compassAccuracyDegrees>%f</mapillary:compassAccuracyDegrees>\n", self.location.heading.headingAccuracy];
        }
        
        if (self.location.deviceMotion)
        {
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:motionX>%f</mapillary:motionX>\n", -self.location.deviceMotion.gravity.x];
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:motionY>%f</mapillary:motionY>\n", self.location.deviceMotion.gravity.y];
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:motionZ>%f</mapillary:motionZ>\n", self.location.deviceMotion.gravity.z];
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:motionAngle>%f</mapillary:motionAngle>\n", atan2(self.location.deviceMotion.gravity.y, -self.location.deviceMotion.gravity.x)];
        }
        
        [locationString appendFormat:@"\t\t\t\t<extensions>\n%@\t\t\t\t</extensions>\n", extensionsString];
        
        // End track point
        [locationString appendString:@"\t\t\t</trkpt>\n"];
        
        // Append footer
        [locationString appendString:footer];
        
        // Append to end of file - footer length
        NSData* locationData = [locationString dataUsingEncoding:NSUTF8StringEncoding];
        
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
        
        unsigned long long fileLength = [attributes fileSize];
        
        [file seekToFileOffset:fileLength-footerLength];
        [file writeData:locationData];
        [file closeFile];
    }
}

@end

@interface MAPGpxLogger()

@property (nonatomic) NSOperationQueue* operationQueue;
@property (nonatomic) NSString* path;
@property (nonatomic) NSDateFormatter* dateFormatter;

@end

@implementation MAPGpxLogger

- (id)initWithFile:(NSString*)path andSequence:(MAPSequence*)sequence
{
    self = [super init];
    
    if (self)
    {
        self.path = path;
        
        self.dateFormatter = [MAPInternalUtils defaultDateFormatter];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        [self.operationQueue addObserver:self forKeyPath:@"operations" options:0 context:&kQueueOperationsChanged];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSString* versionString = [MAPInternalUtils appVersion];
            NSString* dateString = [self.dateFormatter stringFromDate:sequence.sequenceDate];
            NSString* authorString = [[MAPLoginManager currentUser] userName];
            
            NSMutableString* extensionsString = [[NSMutableString alloc] init];
            [extensionsString appendFormat:@"\t\t<mapillary:localTimeZone>%@</mapillary:localTimeZone>\n", [[NSTimeZone systemTimeZone] description]];
            [extensionsString appendFormat:@"\t\t<mapillary:project>%@</mapillary:project>\n", sequence.project ? sequence.project : @"Public"];
            [extensionsString appendFormat:@"\t\t<mapillary:sequenceKey>%@</mapillary:sequenceKey>\n", sequence.sequenceKey];
            [extensionsString appendFormat:@"\t\t<mapillary:timeOffset>%f</mapillary:timeOffset>\n", sequence.timeOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:directionOffset>%f</mapillary:directionOffset>\n", sequence.directionOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceName>%@</mapillary:deviceName>\n", sequence.device.name];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceMake>%@</mapillary:deviceMake>\n", sequence.device.make];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceModel>%@</mapillary:deviceModel>\n", sequence.device.model];
            [extensionsString appendFormat:@"\t\t<mapillary:appVersion>%@</mapillary:appVersion>\n", versionString];
            [extensionsString appendFormat:@"\t\t<mapillary:userKey>%@</mapillary:userKey>\n", [[MAPLoginManager currentUser] userKey]];
            
            NSMutableString* header = [[NSMutableString alloc] init];
            [header appendFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"];
            [header appendFormat:@"<gpx version=\"1.1\" creator=\"Mapillary iOS %@\" xmlns:mapillary=\"http://www.mapillary.com\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n", versionString];
            [header appendFormat:@"\t<metadata>\n"];
            [header appendFormat:@"\t\t<author>\n\t\t\t<name>%@</name>\n\t\t</author>\n", authorString];
            [header appendFormat:@"\t\t<link href=\"https://www.mapillary.com/app/user/%@\"/>\n", authorString];
            [header appendFormat:@"\t\t<time>%@</time>\n", dateString];
            [header appendFormat:@"\t</metadata>\n"];
            [header appendFormat:@"\t<trk>\n"];
            [header appendFormat:@"\t\t<src>Logged by %@ using Mapillary</src>\n", authorString];
            [header appendFormat:@"\t\t<trkseg>\n"];
            
            footer = [NSString stringWithFormat:@"\t\t</trkseg>\n\t</trk>\n\t<extensions>\n%@\t</extensions>\n</gpx>", extensionsString];
            
            [header appendString:footer];
            
            NSData* data = [header dataUsingEncoding:NSUTF8StringEncoding];
            [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            
            NSData* footerData = [footer dataUsingEncoding:NSUTF8StringEncoding];
            footerLength = footerData.length;
        }
    }
    
    return self;
}

/*- (void)dealloc
{
    [self.operationQueue removeObserver:self forKeyPath:@"operations"];
}*/

- (void)addLocation:(MAPLocation*)location
{
    self.busy = YES;
    
    MAPGpxOperation* op = [[MAPGpxOperation alloc] init];
    op.path = self.path;
    op.location = location;
    
    if (location.timestamp)
    {
        op.time = [self.dateFormatter stringFromDate:location.timestamp];
    }
    else
    {
        op.time = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    
    [self.operationQueue addOperation:op];
    
    //NSLog(@"%lu", (unsigned long)self.operationQueue.operationCount);
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operations"] && context == &kQueueOperationsChanged)
    {
        //NSLog(@"%lu", (unsigned long)self.operationQueue.operationCount);
        if ([self.operationQueue.operations count] == 0)
        {
            self.busy = NO;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

