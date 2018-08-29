//
//  MAPGpxLoggerTests.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-30.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@interface MAPGpxLoggerTests : XCTestCase    
@property MAPSequence* sequence;

@end

@implementation MAPGpxLoggerTests

- (void)setUp
{
    [super setUp];
    
    MAPDevice* device = [MAPDevice thisDevice];
    self.sequence = [[MAPSequence alloc] initWithDevice:device];
}

- (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtPath:self.sequence.path error:nil];
    self.sequence = nil;
    
    [super tearDown];
}

- (void)testGpxLogger
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    for (int i = 0; i < 1; i++)
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:50+i*0.1 longitude:50+i*0.1];
        location.timestamp = [NSDate dateWithTimeIntervalSince1970:0];
        
        [self.sequence addLocation:location];
    }
    
    [NSThread sleepForTimeInterval:1];
    
    NSString* file = [NSString stringWithFormat:@"%@/sequence.gpx", self.sequence.path];
    NSString* contents = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    MAPDevice* device = [MAPDevice thisDevice];
    
    NSString* expected = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<gpx version=\"1.1\" creator=\"Mapillary iOS (null)\" xmlns:mapillary=\"http://www.mapillary.com\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n\t<metadata>\n\t\t<author>\n\t\t\t<name>(null)</name>\n\t\t</author>\n\t\t<link href=\"https://www.mapillary.com/app/user/(null)\"/>\n\t\t<time>%@</time>\n\t</metadata>\n\t<trk>\n\t\t<src>Logged by (null) using Mapillary</src>\n\t\t<trkseg>\n\t\t\t<trkpt lat=\"50.000000\" lon=\"50.000000\">\n\t\t\t\t<time>1970-01-01T00:00:00.000Z</time>\n\t\t\t\t<fix>2d</fix>\n\t\t\t\t<extensions>\n\t\t\t\t\t<mapillary:gpsAccuracyMeters>0.000000</mapillary:gpsAccuracyMeters>\n\t\t\t\t</extensions>\n\t\t\t</trkpt>\n\t\t</trkseg>\n\t</trk>\n\t<extensions>\n\t\t<mapillary:localTimeZone>Europe/Stockholm (GMT+1) offset 3600</mapillary:localTimeZone>\n\t\t<mapillary:project>Public</mapillary:project>\n\t\t<mapillary:sequenceKey>%@</mapillary:sequenceKey>\n\t\t<mapillary:timeOffset>-1.000000</mapillary:timeOffset>\n\t\t<mapillary:directionOffset>-1.000000</mapillary:directionOffset>\n\t\t<mapillary:deviceUUID>%@</mapillary:deviceUUID>\n\t\t<mapillary:deviceMake>%@</mapillary:deviceMake>\n\t\t<mapillary:deviceModel>%@</mapillary:deviceModel>\n\t\t<mapillary:appVersion>(null)</mapillary:appVersion>\n\t\t<mapillary:userKey>(null)</mapillary:userKey>\n\t\t<mapillary:appNameString>mapillary_ios</mapillary:appNameString>\n\t</extensions>\n</gpx>", [dateFormatter stringFromDate:self.sequence.sequenceDate], self.sequence.sequenceKey, device.UUID, device.make, device.model];
    
    XCTAssertTrue([contents isEqualToString:expected]);
}

@end
