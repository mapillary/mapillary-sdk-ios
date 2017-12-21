//
//  MAPSequenceTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2017-10-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"
#import "MAPInternalUtils.h"

@interface MAPSequenceTests : XCTestCase

@property MAPDevice* device;
@property MAPSequence* sequence;

@end

@implementation MAPSequenceTests

- (void)setUp
{
    [super setUp];
    
    self.device = [[MAPDevice alloc] init];
    self.device.name = @"iPhone7,2";
    self.device.make = @"Apple";
    self.device.model = @"iPhone 6";
    
    self.sequence = [[MAPSequence alloc] initWithDevice:self.device];
}

- (void)tearDown
{
    [MAPFileManager deleteSequence:self.sequence];
    self.sequence = nil;
    self.device = nil;
    
    [super tearDown];
}

- (void)testSanity
{
    BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:self.sequence.path isDirectory:nil];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self.sequence.path stringByAppendingPathComponent:@"sequence.gpx"] isDirectory:nil];
    
    XCTAssertNotNil(self.sequence.sequenceDate);
    XCTAssertNotNil(self.sequence.sequenceKey);
    XCTAssertNotNil(self.sequence.device);
    XCTAssertNotNil(self.sequence.project);
    XCTAssertNotNil(self.sequence.path);
    XCTAssertNotNil([self.sequence listImages]);
    
    XCTAssert(self.sequence.timeOffset == 0);
    XCTAssert(self.sequence.directionOffset == -1);
    XCTAssert([self.sequence listImages].count == 0);
    
    XCTAssertTrue(directoryExists);
    XCTAssertTrue(fileExists);
    
    [MAPFileManager deleteSequence:self.sequence];
    
    directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:self.sequence.path isDirectory:nil];
    XCTAssertFalse(directoryExists);
}

- (void)testAddImagesFromData
{
    // There should be no images
    NSArray* images = [self.sequence listImages];
    XCTAssertNotNil(images);
    XCTAssert(images.count == 0);
    
    // Test with invalid data
    NSData* imageData = nil;
    [self.sequence addImageWithData:imageData date:nil location:nil];
    XCTAssert(images.count == 0);
    
    // Test with valid data
    imageData = [self createImageData];
    int nbrImages = arc4random()%100;
    for (int i = 0; i < nbrImages; i++)
    {
        [self.sequence addImageWithData:imageData date:nil location:nil];
    }

    // There should now be nbrImages images
    images = [self.sequence listImages];
    XCTAssert(images.count == nbrImages);
}

- (void)testAddImagesFromFile
{
    NSString* path = [NSString stringWithFormat:@"%@/%@", [MAPInternalUtils documentsDirectory], @"temp.jpg"];
    
    NSData* imageData = [self createImageData];
    [imageData writeToFile:path atomically:YES];
    
    int nbrImages = arc4random()%100;
    for (int i = 0; i < nbrImages; i++)
    {
        [self.sequence addImageWithPath:path date:nil location:nil];
    }
    
    // There should now be nbrImages images
    XCTAssert([self.sequence listImages].count == nbrImages);
    
    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testAddLocations
{
    self.sequence = [[MAPSequence alloc] initWithDevice:self.device];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Number of locations added should be the same as the number returned"];
    
    int nbrPositions = arc4random()%1000;
    MAPLocation* location = [[MAPLocation alloc] init];
    for (int i = 0; i < nbrPositions; i++)
    {
        [self.sequence addLocation:location];
    }
    
    // There should now be nbrPositions locations
    
    [self.sequence listLocations:^(NSArray *array) {
        
         XCTAssert(array.count == nbrPositions);
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
        
    }];
}

- (void)testLocationForDate
{
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:500];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    [self.sequence addLocation:a];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:1000];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(100, 100) altitude:100 horizontalAccuracy:30 verticalAccuracy:30 timestamp:b.timestamp];
    [self.sequence addLocation:b];
    
    // Test with date inbetween A and B
    MAPLocation* result1 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:750]];
    XCTAssertEqual(result1.location.coordinate.latitude, AVG(a.location.coordinate.latitude, b.location.coordinate.latitude));
    XCTAssertEqual(result1.location.coordinate.longitude, AVG(a.location.coordinate.longitude, b.location.coordinate.longitude));
    
    // Test with nil date
    MAPLocation* result2 = [self.sequence locationForDate:nil];
    XCTAssertNil(result2);
    
    // Test with a's date
    MAPLocation* result3 = [self.sequence locationForDate:a.timestamp];
    XCTAssertEqual(result3.location.coordinate.latitude, a.location.coordinate.latitude);
    XCTAssertEqual(result3.location.coordinate.longitude, a.location.coordinate.longitude);
    
    // Test with b's date
    MAPLocation* result4 = [self.sequence locationForDate:b.timestamp];
    XCTAssertEqual(result4.location.coordinate.latitude, b.location.coordinate.latitude);
    XCTAssertEqual(result4.location.coordinate.longitude, b.location.coordinate.longitude);
    
    // Test with date before a, should be nil
    MAPLocation* result5 = [self.sequence locationForDate:[NSDate dateWithTimeInterval:-100 sinceDate:a.timestamp]];
    XCTAssertNil(result5);
    
    // Test with date after b, should be nil
    MAPLocation* result6 = [self.sequence locationForDate:[NSDate dateWithTimeInterval:100 sinceDate:b.timestamp]];
    XCTAssertNil(result6);
}

- (void)testListLocationsPerformance
{
    srand(1234);
    
    for (int i = 0; i < 5000; i++)
    {
        MAPLocation* a = [[MAPLocation alloc] init];
        a.timestamp = [NSDate dateWithTimeIntervalSince1970:rand()];
        [self.sequence addLocation:a];
    }
    
    [self measureBlock:^{
        
        XCTestExpectation* expectation = [self expectationWithDescription:@"Number of locations added should be the same as the number returned"];
        
        [self.sequence listLocations:^(NSArray *array) {
            
            [expectation fulfill];
            
        }];
        
        // Wait for test to finish
        [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
            
            if (error)
            {
                XCTFail(@"Expectation failed with error: %@", error);
            }
            
        }];
    }];
}

- (void)testAddMissingGpxFile
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Trying to add missing GPX file"];
    
    [self.sequence addGpx:@"path/to/file" done:^{
        
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
        
    }];
}

- (void)testAddMapillaryGpxFile
{
    // TODO add bigger test file
    
    NSString* path = [NSString stringWithFormat:@"%@/test.gpx", [MAPInternalUtils documentsDirectory]];
    
    NSString* gpx = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<gpx version=\"1.1\" creator=\"Mapillary iOS 1.0\" xmlns:mapillary=\"http://www.mapillary.com\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n\t<metadata>\n\t\t<author>\n\t\t\t<name>millenbop</name>\n\t\t</author>\n\t\t<link href=\"https://www.mapillary.com/app/user/millenbop\"/>\n\t\t<time>1970-01-01T01:00:00.000Z</time>\n\t</metadata>\n\t<trk>\n\t\t<src>Logged by millenbop using Mapillary</src>\n\t\t<trkseg>\n\t\t\t<trkpt lat=\"50.000000\" lon=\"50.000000\">\n\t\t\t\t<time>1970-01-01T01:00:00.000Z</time>\n\t\t\t\t<fix>2d</fix>\n\t\t\t\t<extensions>\n\t\t\t\t\t<mapillary:gpsAccuracyMeters>0.000000</mapillary:gpsAccuracyMeters>\n\t\t\t\t</extensions>\n\t\t\t</trkpt>\n\t\t</trkseg>\n\t</trk>\n\t<extensions>\n\t\t<mapillary:localTimeZone>Europe/Stockholm (GMT+2) offset 7200 (Daylight)</mapillary:localTimeZone>\n\t\t<mapillary:project>Public</mapillary:project>\n\t\t<mapillary:sequenceKey>1234-5678-9ABC-DEF</mapillary:sequenceKey>\n\t\t<mapillary:timeOffset>0.000000</mapillary:timeOffset>\n\t\t<mapillary:directionOffset>-1.000000</mapillary:directionOffset>\n\t\t<mapillary:deviceName>iPhone7,2</mapillary:deviceName>\n\t\t<mapillary:deviceMake>Apple</mapillary:deviceMake>\n\t\t<mapillary:deviceModel>iPhone 6</mapillary:deviceModel>\n\t\t<mapillary:appVersion>(null)</mapillary:appVersion>\n\t\t<mapillary:userKey>(null)</mapillary:userKey>\n\t\t</extensions>\n</gpx>";
    
    [gpx writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Adding Mapillary GPX file"];
    
    __weak MAPSequenceTests* weakSelf = self;
    
    [weakSelf.sequence addGpx:path done:^{
        
        [weakSelf.sequence listLocations:^(NSArray *array) {
            
            XCTAssert(array.count == 1);
            [expectation fulfill];
            
        }];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

- (void)testAddMapboxGpxFile
{
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"mapbox-test" ofType:@"gpx"];

    XCTestExpectation* expectation = [self expectationWithDescription:@"Adding non Mapillary GPX file"];
    
    __weak MAPSequenceTests* weakSelf = self;
    
    [weakSelf.sequence addGpx:path done:^{
        
        [weakSelf.sequence listLocations:^(NSArray *array) {
            
            XCTAssert(array.count == 206);
            [expectation fulfill];
            
        }];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

- (void)testCaching
{
    __block NSTimeInterval timeStart = 0;
    __block NSTimeInterval timeStartCached = 0;
    __block NSTimeInterval timeEnd = 0;
    __block NSTimeInterval timeEndCached = 0;
    int nbrLocations = 1000;
    
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"mapbox-test" ofType:@"gpx"];
    XCTestExpectation* expectation = [self expectationWithDescription:@"Caching should be faster than non-cached"];
    
    srand(1234);
    
    for (int i = 0; i < nbrLocations; i++)
    {
        MAPLocation* a = [[MAPLocation alloc] init];
        a.timestamp = [NSDate dateWithTimeIntervalSince1970:rand()];
        [self.sequence addLocation:a];
    }
    
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        timeStart = [NSDate timeIntervalSinceReferenceDate];
        
        [self.sequence listLocations:^(NSArray *array) {
            timeEnd = [NSDate timeIntervalSinceReferenceDate];
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, 60);
    }
    
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        timeStartCached = [NSDate timeIntervalSinceReferenceDate];
        
        [self.sequence listLocations:^(NSArray *array) {
            timeEndCached = [NSDate timeIntervalSinceReferenceDate];
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, 60);
    }
    
    NSTimeInterval timeNotCached = timeEnd-timeStart;
    NSTimeInterval timeCached = timeEndCached-timeStartCached;
    
    XCTAssert(timeCached < timeNotCached);
    
    [expectation fulfill];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

#pragma mark - Utils

- (NSData*)createImageData
{
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 100, 100));
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    return UIImageJPEGRepresentation(image, 1);
}

@end
