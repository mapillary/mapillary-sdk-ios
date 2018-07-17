//
//  MAPLocationTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2018-03-06.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"

@interface MAPLocationTests : XCTestCase

@end

@implementation MAPLocationTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testEqual
{
    MAPLocation* location1 = [[MAPLocation alloc] init];
    location1.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    MAPLocation* location2 = [[MAPLocation alloc] init];
    location2.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    XCTAssertTrue([location1 isEqual:location2]);
    XCTAssertTrue([location2 isEqual:location1]);
    XCTAssertTrue([location1 isEqual:location1]);
}

- (void)testNotEqual
{
    MAPLocation* location1 = [[MAPLocation alloc] init];
    location1.location = [[CLLocation alloc] initWithLatitude:60 longitude:60];
    
    MAPLocation* location2 = [[MAPLocation alloc] init];
    location2.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    XCTAssertFalse([location1 isEqual:location2]);
    XCTAssertFalse([location2 isEqual:location1]);
}

- (void)testDescription
{
    MAPLocation* location = [[MAPLocation alloc] init];
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    XCTAssertNotNil(location.description);
}

- (void)testTimestring
{
    MAPLocation* location = [[MAPLocation alloc] init];
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    XCTAssertNotNil(location.timeString);
}

@end
