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
    
    self.sequence = [[MAPSequence alloc] init];
    
    self.sequence.project = @"Public";
    self.sequence.device.name = @"iPhone7,2";
    self.sequence.device.make = @"Apple";
    self.sequence.device.model = @"iPhone 6";
    
    NSLog(@"%@", self.sequence.path);
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
        location.latitude = [NSNumber numberWithDouble:50+i*0.1];
        location.longitude = [NSNumber numberWithDouble:50+i*0.1];
        location.date = [NSDate date];
        
        [NSThread sleepForTimeInterval:0.1];
        
        [self.sequence addLocation:location];
    }    
    
    NSString* file = [NSString stringWithFormat:@"%@/sequence.gpx", self.sequence.path];
    NSString* contents = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"\n\n----------------------------\n%@\n\n----------------------------", contents);
    
}


@end
