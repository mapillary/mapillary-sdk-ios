//
//  MAPGpxLogger.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-03-21.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPGpxLogger.h"
#import "MAPUtils.h"
#import "MAPLoginManager.h"

@interface MAPGpxOperation : NSOperation

@property (nonatomic) NSString* path;
@property (nonatomic) MAPLocation* location;
@property (nonatomic) NSString* time;

@end

@implementation MAPGpxOperation

- (void)main
{
    @autoreleasepool
    {
        NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:self.path];
        NSMutableString* locationString = [[NSMutableString alloc] init];
        
        // Add location
        [locationString appendFormat:@"\t\t\t<trkpt lat=\"%f\" lon=\"%f\">", self.location.location.coordinate.latitude, self.location.location.coordinate.longitude];
        
        // Add eleveation if available
        if (self.location.location.verticalAccuracy > 0)
        {
            [locationString appendFormat:@"<ele>%f</ele>", self.location.location.altitude];
        }
        
        // Add time
        [locationString appendFormat:@"<time>%@</time>", self.time];
        
        // Add fix
        if (self.location.location.verticalAccuracy > 0)
        {
            [locationString appendString:@"<fix>3d</fix>"];
        }
        else
        {
            [locationString appendString:@"<fix>2d</fix>"];
        }
        
        
        // Add exgtensions
        // TODO need accelerometer?
        // TODO need direction?
        
        NSMutableString* extensionsString = [[NSMutableString alloc] init];
        [extensionsString appendFormat:@"<mapillary:gpsAccuracyMeters>%f</mapillary:gpsAccuracyMeters>", self.location.location.horizontalAccuracy];
        [extensionsString appendFormat:@"<mapillary:compassTrueHeading>%f</mapillary:compassTrueHeading>", self.location.heading.trueHeading];
        [extensionsString appendFormat:@"<mapillary:compassMagneticHeading>%f</mapillary:compassMagneticHeading>", self.location.heading.magneticHeading];
        [extensionsString appendFormat:@"<mapillary:compassAccuracyDegrees>%f</mapillary:compassAccuracyDegrees>", self.location.heading.headingAccuracy];
        [locationString appendFormat:@"<extensions>%@</extensions>", extensionsString];
        
        // End track point
        [locationString appendString:@"</trkpt>\n"];
        
        // Append footer
        NSString* footer = @"\t\t</trkseg>\n\t</trk>\n</gpx>";
        [locationString appendString:footer];
        
        // Append to end of file - footer length
        NSData* locationData = [locationString dataUsingEncoding:NSUTF8StringEncoding];
        NSData* footerData = [footer dataUsingEncoding:NSUTF8StringEncoding];
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
        
        unsigned long long footerLength = footerData.length;
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
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSString* versionString = [MAPUtils appVersion];
            NSString* dateString = [self.dateFormatter stringFromDate:sequence.sequenceDate];
            NSString* authorString = [[MAPLoginManager currentUser] userName];
            
            NSMutableString* extensionsString = [[NSMutableString alloc] init];
            [extensionsString appendFormat:@"\t\t<mapillary:localTimeZone>%@</mapillary:localTimeZone>\n", [[NSTimeZone systemTimeZone] description]];
            [extensionsString appendFormat:@"\t\t<mapillary:project>%@</mapillary:project>\n", sequence.project ? sequence.project : @""];
            [extensionsString appendFormat:@"\t\t<mapillary:sequenceKey>%@</mapillary:sequenceKey>\n", sequence.sequenceKey];
            [extensionsString appendFormat:@"\t\t<mapillary:timeOffset>%f</mapillary:timeOffset>\n", sequence.timeOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:directionOffset>%f</mapillary:directionOffset>\n", sequence.directionOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceName>%@</mapillary:deviceName>\n", sequence.device.name];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceMake>%@</mapillary:deviceMake>\n", sequence.device.make];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceModel>%@</mapillary:deviceModel>\n", sequence.device.model];
            [extensionsString appendFormat:@"\t\t<mapillary:appVersion>%@</mapillary:appVersion>\n", versionString];
            [extensionsString appendFormat:@"\t\t<mapillary:userKey>%@</mapillary:userKey>\n", [[MAPLoginManager currentUser] userKey]];
            [extensionsString appendFormat:@"\t\t<mapillary:uploadHash>%@</mapillary:uploadHash>\n", [[MAPLoginManager currentUser] uploadHash]];
            // TODO MAPSettingsTokenValid needed?
            
            NSMutableString* header = [[NSMutableString alloc] init];
            [header appendFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"];
            [header appendFormat:@"<gpx version=\"1,0\" creator=\"Mapillary iOS %@\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.topografix.com/GPX/1/0\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd\">\n", versionString];
            [header appendFormat:@"\t<metadata>\n"];
            [header appendFormat:@"\t\t<author>\n\t\t\t<name>%@</name>\n\t\t</author>\n", authorString];
            [header appendFormat:@"\t\t<time>%@</time>\n", dateString];
            [header appendFormat:@"\t\t<link href=\"https://www.mapillary.com/app/user/%@\"/>\n", authorString];
            [header appendFormat:@"\t</metadata>\n"];
            [header appendFormat:@"\t<extensions>\n%@\t</extensions>\n", extensionsString];
            [header appendFormat:@"\t<trk>\n"];
            [header appendFormat:@"\t\t<src>Logged by %@ using Mapillary</src>\n", authorString];
            [header appendFormat:@"\t\t<trkseg>\n"];
            
            NSString* footer = @"\t\t</trkseg>\n\t</trk>\n</gpx>";
            [header appendString:footer];

            
            NSData* data = [header dataUsingEncoding:NSUTF8StringEncoding];
            
            [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
        }
    }
    
    return self;
}

- (void)add:(MAPLocation*)location
{
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

@end

