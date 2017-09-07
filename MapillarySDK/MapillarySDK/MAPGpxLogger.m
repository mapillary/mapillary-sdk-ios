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
        [locationString appendFormat:@"\t\t\t<trkpt lat=\"%f\" lon=\"%f\">", self.location.latitude.doubleValue, self.location.longitude.doubleValue];
        
        // Add eleveation if available
        if (self.location.elevation != nil)
        {
            [locationString appendFormat:@"<ele>%f</ele>", self.location.elevation.doubleValue];
        }
        
        // Add time
        [locationString appendFormat:@"<time>%@</time>", self.time];
        
        // Add fix
        if (self.location.elevation != nil)
        {
            [locationString appendString:@"<fix>3d</fix>"];
        }
        else
        {
            [locationString appendString:@"<fix>2d</fix>"];
        }
        
        
        // Add exgtensions
        // TODO Add bearing etr
        // TODO Add accelerometer
        // TODO precision
        
        /*
         
         {
         
         "MAPCalculatedHeading" : 193.1933,
         
         "MAPGPSAccuracyMeters" : "10.000000",
         
         "MAPPhotoUUID" : "10B77312-48B4-4817-8155-00753C944DC5",
         "MAPDirection" : 9,
         
         "MAPCompassHeading"
            "TrueHeading" : 30.13333,
            "MagneticHeading" : 26.32394,
            "AccuracyDegrees" : 25
         
         
         */
        
        
        
        NSMutableString* extensionsString = [[NSMutableString alloc] init];
        //[extensionsString appendFormat:@"<mapillary:localTimeZone>%@</>", timeZoneString];
        
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
            [extensionsString appendFormat:@"\t\t<mapillary:localTimeZone>%@</>\n", [[NSTimeZone systemTimeZone] description]];
            [extensionsString appendFormat:@"\t\t<mapillary:project>%@</>\n", sequence.project ? sequence.project : @""];
            [extensionsString appendFormat:@"\t\t<mapillary:userKey>%@</>\n", [[MAPLoginManager currentUser] userKey]];
            [extensionsString appendFormat:@"\t\t<mapillary:sequenceKey>%@</>\n", sequence.sequenceKey];
            [extensionsString appendFormat:@"\t\t<mapillary:timeOffset>%f</>\n", sequence.timeOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:bearingOffset>%f</>\n", sequence.bearingOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceName>%@</>\n", sequence.device.name];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceMake>%@</>\n", sequence.device.make];
            [extensionsString appendFormat:@"\t\t<mapillary:deviceModel>%@</>\n", sequence.device.model];
            [extensionsString appendFormat:@"\t\t<mapillary:uploadHash>%@</>\n", @"TODO"];
            [extensionsString appendFormat:@"\t\t<mapillary:appVersion>%@</>\n", versionString];
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
    
    if (location.date)
    {
        op.time = [self.dateFormatter stringFromDate:location.date];
    }
    else
    {
        op.time = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    
    [self.operationQueue addOperation:op];
    
    //NSLog(@"%lu", (unsigned long)self.operationQueue.operationCount);
}

@end
