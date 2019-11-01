//
//  MAPInternalUtilsTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2018-02-14.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"
#import "MAPInternalUtils.h"

@interface MAPInternalUtilsTests : XCTestCase

@end

@implementation MAPInternalUtilsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInterpolation
{
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:0];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:1000];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(100, 100) altitude:100 horizontalAccuracy:30 verticalAccuracy:30 timestamp:b.timestamp];
    
    // Order A and B
    MAPLocation* resultAB = [MAPInternalUtils locationBetweenLocationA:a andLocationB:b forDate:[NSDate dateWithTimeIntervalSince1970:500]];
    
    // Order B and A
    MAPLocation* resultBA = [MAPInternalUtils locationBetweenLocationA:b andLocationB:a forDate:[NSDate dateWithTimeIntervalSince1970:500]];
    
    // Test1 and test2 should be the same
    XCTAssertTrue([resultAB isEqualToLocation:resultBA]);
    
    // Coordinate should be inbetween A and B
    XCTAssertEqual(resultAB.location.coordinate.latitude, AVG(a.location.coordinate.latitude, b.location.coordinate.latitude));
    XCTAssertEqual(resultAB.location.coordinate.longitude, AVG(a.location.coordinate.longitude, b.location.coordinate.longitude));
    
    // Test with same coordinates
    MAPLocation* resultAA = [MAPInternalUtils locationBetweenLocationA:a andLocationB:a forDate:[NSDate dateWithTimeIntervalSince1970:500]];
    XCTAssertTrue([a isEqualToLocation:resultAA]);
    
    // Test with nil locations
    MAPLocation* resultNilNilNil = [MAPInternalUtils locationBetweenLocationA:nil andLocationB:nil forDate:nil];
    MAPLocation* resultANilNil = [MAPInternalUtils locationBetweenLocationA:a andLocationB:nil forDate:nil];
    MAPLocation* resultNilBNil = [MAPInternalUtils locationBetweenLocationA:nil andLocationB:b forDate:nil];
    XCTAssertNil(resultNilNilNil);
    XCTAssertNil(resultANilNil);
    XCTAssertNil(resultNilBNil);
    
    // Test with nil date, should be inbetween A and B, i.e. same as resultAB
    MAPLocation* resultABNil = [MAPInternalUtils locationBetweenLocationA:a andLocationB:b forDate:nil];
    XCTAssertTrue([resultAB isEqualToLocation:resultABNil]);
}

- (void)testCalculateHeadingFromCoords
{
    // Verified using http://instantglobe.com/CRANES/GeoCoordTool.html
    
    CLLocationCoordinate2D A = CLLocationCoordinate2DMake(39.099912, -94.581213);
    CLLocationCoordinate2D B = CLLocationCoordinate2DMake(38.627089, -90.200203);
    
    NSNumber* result = [MAPInternalUtils calculateHeadingFromCoordA:A B:B];
    
    XCTAssertEqual(result.intValue, 96); // 96.51262423499946
}

- (void)testCalculateHeadingFromCoords2
{
    CLLocationCoordinate2D A = CLLocationCoordinate2DMake(55.596, 13.023); // Malmö
    CLLocationCoordinate2D B = CLLocationCoordinate2DMake(59.334415, 18.110103); // Stockholm
    
    NSNumber* result = [MAPInternalUtils calculateHeadingFromCoordA:A B:B];
    
    XCTAssertEqual(result.intValue, 34); // 34.07484069345571
}

- (void)testCalculateHeadingFromCoordsReverse
{
    CLLocationCoordinate2D A = CLLocationCoordinate2DMake(39.099912, -94.581213);
    CLLocationCoordinate2D B = CLLocationCoordinate2DMake(38.627089, -90.200203);
    
    NSNumber* result = [MAPInternalUtils calculateHeadingFromCoordA:B B:A];
    
    XCTAssertEqual(result.intValue, 279); // 279.26239975009179
}

@end
