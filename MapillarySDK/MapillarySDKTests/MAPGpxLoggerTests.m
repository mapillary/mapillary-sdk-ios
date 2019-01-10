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
    
    NSString* expected = [NSString stringWithFormat:
                          @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
                          "<gpx version=\"1.1\" creator=\"Mapillary iOS (null)\" xmlns:mapillary=\"http://www.mapillary.com\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n\t<metadata>\n\t\t<author>\n"
                          "\t\t\t<name>(null)</name>\n"
                          "\t\t</author>\n"
                          "\t\t<link href=\"https://www.mapillary.com/app/user/(null)\"/>\n"
                          "\t\t<time>%@</time>\n"
                          "\t</metadata>\n"
                          "\t<extensions>\n"
                          "\t\t<mapillary:MAPAppNameString>mapillary_ios</mapillary:MAPAppNameString>\n"
                          "\t\t<mapillary:MAPDeviceMake>%@</mapillary:MAPDeviceMake>\n"
                          "\t\t<mapillary:MAPDeviceModel>%@</mapillary:MAPDeviceModel>\n"
                          "\t\t<mapillary:MAPDeviceUUID>%@</mapillary:MAPDeviceUUID>\n"
                          "\t\t<mapillary:MAPDirectionOffset>0.000000</mapillary:MAPDirectionOffset>\n"
                          "\t\t<mapillary:MAPLocalTimeZone>%@</mapillary:MAPLocalTimeZone>\n"
                          "\t\t<mapillary:MAPSettingsUserKey>(null)</mapillary:MAPSettingsUserKey>\n"
                          "\t\t<mapillary:MAPSequenceUUID>%@</mapillary:MAPSequenceUUID>\n"
                          "\t\t<mapillary:MAPTimeOffset>0.000000</mapillary:MAPTimeOffset>\n"
                          "\t\t<mapillary:MAPVersionString>(null)</mapillary:MAPVersionString>\n"
                          "\t</extensions>\n"
                          "\t<trk>\n"
                          "\t\t<src>Logged by (null) using Mapillary</src>\n"
                          "\t\t<trkseg>\n"
                          "\t\t\t<trkpt lat=\"50.000000\" lon=\"50.000000\">\n"
                          "\t\t\t\t<ele>0.000000</ele>\n"
                          "\t\t\t\t<time>1970-01-01T00:00:00.000Z</time>\n"
                          "\t\t\t\t<extensions>\n"
                          "\t\t\t\t\t<mapillary:MAPGPSAccuracyMeters>0.000000</mapillary:MAPGPSAccuracyMeters>\n"
                          "\t\t\t\t\t<mapillary:MAPGPSSpeed>-1.000000</mapillary:MAPGPSSpeed>\n"
                          "\t\t\t\t</extensions>\n"
                          "\t\t\t</trkpt>\n\t\t</trkseg>\n"
                          "\t</trk>\n</gpx>",
                          [dateFormatter stringFromDate:self.sequence.sequenceDate], device.make, device.model, device.UUID, [[NSTimeZone systemTimeZone] description], self.sequence.sequenceKey];
    
    XCTAssertTrue([contents isEqualToString:expected]);
}

@end
