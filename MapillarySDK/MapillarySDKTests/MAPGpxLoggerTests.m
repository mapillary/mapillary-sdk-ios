//
//  MAPGpxLoggerTests.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-30.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"

#import "MAPUtils.h"

@interface MAPGpxLoggerTests : XCTestCase
    
@property MAPSequence* sequence;

@end

@implementation MAPGpxLoggerTests

- (void)setUp
{
    [super setUp];
    
    MAPDevice* device = [[MAPDevice alloc] init];
    device.name = @"iPhone7,2";
    device.make = @"Apple";
    device.model = @"iPhone 6";
    
    self.sequence = [[MAPSequence alloc] initWithDevice:device];
    self.sequence.project = @"Public";
}

- (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtPath:self.sequence.path error:nil];
    self.sequence = nil;
    
    [super tearDown];
}

- (void)testGpx
{
    for (int i = 0; i < 10; i++)
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:50+i*0.1 longitude:50+i*0.1];
        location.timestamp = [NSDate date];
        
        [NSThread sleepForTimeInterval:0.1];
        
        [self.sequence addLocation:location];
    }    
    
    NSString* file = [NSString stringWithFormat:@"%@/sequence.gpx", self.sequence.path];
    NSString* contents = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"\n\n----------------------------\n%@\n\n----------------------------", contents);
    
}


@end
