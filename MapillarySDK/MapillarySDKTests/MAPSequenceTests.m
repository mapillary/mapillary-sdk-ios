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
#import "MAPSequence+Private.h"
#import "MAPDefines.h"
#import "MAPExifTools.h"

@interface MAPSequenceTests : XCTestCase <MAPUploadManagerDelegate>

@property MAPDevice* device;
@property MAPSequence* sequence;
@property XCTestExpectation* expectationImagesProcessed;

@end

@implementation MAPSequenceTests

- (void)setUp
{
    [super setUp];
    
    self.device = [MAPDevice thisDevice];    
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
    XCTAssertNotNil(self.sequence.path);
    XCTAssertNotNil([self.sequence getImages]);
    
    XCTAssertNil(self.sequence.timeOffset);
    XCTAssertNil(self.sequence.directionOffset);
    
    XCTAssert([self.sequence getImages].count == 0);
    
    XCTAssertTrue(directoryExists);
    XCTAssertTrue(fileExists);
    
    [MAPFileManager deleteSequence:self.sequence];
    
    directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:self.sequence.path isDirectory:nil];
    XCTAssertFalse(directoryExists);
}

- (void)testInit
{
    MAPSequence* s1 = [[MAPSequence alloc] initWithDevice:self.device];
    MAPSequence* s2 = [[MAPSequence alloc] initWithDevice:self.device andDate:[NSDate date]];
    MAPSequence* s3 = [[MAPSequence alloc] initWithPath:s1.path parseGpx:NO];
    
    XCTAssertNotNil(s1);
    XCTAssertNotNil(s2);
    XCTAssertNotNil(s3);
    
    [MAPFileManager deleteSequence:s1];
    [MAPFileManager deleteSequence:s2];
    [MAPFileManager deleteSequence:s3];
}

- (void)testAddImagesFromData
{
    // There should be no images
    NSArray* images = [self.sequence getImages];
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
    images = [self.sequence getImages];
    XCTAssert(images.count == nbrImages);
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Number of images should be the same as number of images added"];
    
    [self.sequence getImagesAsync:^(NSArray *images) {
        
        XCTAssertEqual(images.count, nbrImages);
        
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
        
    }];
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
    XCTAssert([self.sequence getImages].count == nbrImages);
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Number of images should be the same as number of images added"];        
    
    [self.sequence getImagesAsync:^(NSArray *images) {
        
        XCTAssertEqual(images.count, nbrImages);
        
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
        
    }];
    
    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testAddLocations
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Number of locations added should be the same as the number returned"];
    
    int nbrPositions = arc4random()%1000;
    
    for (int i = 0; i < nbrPositions; i++)
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:50+i*0.001 longitude:50+i*0.001];
        [self.sequence addLocation:location];
    }
    
    // There should now be nbrPositions locations
    
    [self.sequence getLocationsAsync:^(NSArray *array) {
        
         XCTAssert(array.count == nbrPositions);
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
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
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(60, 60) altitude:100 horizontalAccuracy:30 verticalAccuracy:30 timestamp:b.timestamp];
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
    
    // Test with date before a, should be a
    MAPLocation* result5 = [self.sequence locationForDate:[NSDate dateWithTimeInterval:-100 sinceDate:a.timestamp]];
    XCTAssertEqual(result5.location.coordinate.latitude, a.location.coordinate.latitude);
    XCTAssertEqual(result5.location.coordinate.latitude, a.location.coordinate.longitude);
    
    // Test with date after b, should be b
    MAPLocation* result6 = [self.sequence locationForDate:[NSDate dateWithTimeInterval:100 sinceDate:b.timestamp]];
    XCTAssertEqual(result6.location.coordinate.latitude, b.location.coordinate.latitude);
    XCTAssertEqual(result6.location.coordinate.latitude, b.location.coordinate.longitude);
}

- (void)testGetLocationsPerformance
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
        
        [self.sequence getLocationsAsync:^(NSArray *array) {
            
            [expectation fulfill];
            
        }];
        
        // Wait for test to finish
        [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
            
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
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
        
    }];
}

- (void)testAddMapillaryGpxFile
{
    NSString* path = [NSString stringWithFormat:@"%@/test.gpx", [MAPInternalUtils documentsDirectory]];
    
    NSString* gpx = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<gpx version=\"1.1\" creator=\"Mapillary iOS 1.0\" xmlns:mapillary=\"http://www.mapillary.com\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n\t<metadata>\n\t\t<author>\n\t\t\t<name>millenbop</name>\n\t\t</author>\n\t\t<link href=\"https://www.mapillary.com/app/user/millenbop\"/>\n\t\t<time>1970-01-01T01:00:00.000Z</time>\n\t</metadata>\n\t<trk>\n\t\t<src>Logged by millenbop using Mapillary</src>\n\t\t<trkseg>\n\t\t\t<trkpt lat=\"50.000000\" lon=\"50.000000\">\n\t\t\t\t<time>1970-01-01T01:00:00.000Z</time>\n\t\t\t\t<fix>2d</fix>\n\t\t\t\t<extensions>\n\t\t\t\t\t<mapillary:gpsAccuracyMeters>0.000000</mapillary:gpsAccuracyMeters>\n\t\t\t\t</extensions>\n\t\t\t</trkpt>\n\t\t</trkseg>\n\t</trk>\n\t<extensions>\n\t\t<mapillary:localTimeZone>Europe/Stockholm (GMT+2) offset 7200 (Daylight)</mapillary:localTimeZone>\n\t\t<mapillary:project>Public</mapillary:project>\n\t\t<mapillary:sequenceKey>1234-5678-9ABC-DEF</mapillary:sequenceKey>\n\t\t<mapillary:timeOffset>0.000000</mapillary:timeOffset>\n\t\t<mapillary:directionOffset>-1.000000</mapillary:directionOffset>\n\t\t<mapillary:deviceUUID>iPhone7,2</mapillary:deviceUUID>\n\t\t<mapillary:deviceMake>Apple</mapillary:deviceMake>\n\t\t<mapillary:deviceModel>iPhone 6</mapillary:deviceModel>\n\t\t<mapillary:appVersion>(null)</mapillary:appVersion>\n\t\t<mapillary:userKey>(null)</mapillary:userKey>\n\t\t</extensions>\n</gpx>";
    
    [gpx writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Adding Mapillary GPX file"];
    
    __weak MAPSequenceTests* weakSelf = self;
    
    [weakSelf.sequence addGpx:path done:^{
        
        [weakSelf.sequence getLocationsAsync:^(NSArray *array) {
            
            XCTAssert(array.count == 1);
            [expectation fulfill];
            
        }];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
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
        
        [weakSelf.sequence getLocationsAsync:^(NSArray *array) {
            
            XCTAssert(array.count == 205);
            [expectation fulfill];
            
        }];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
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
        a.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
        [self.sequence addLocation:a];
    }
    
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        timeStart = [NSDate timeIntervalSinceReferenceDate];
        
        [self.sequence getLocationsAsync:^(NSArray *array) {
            timeEnd = [NSDate timeIntervalSinceReferenceDate];
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, 60);
    }
    
    {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        timeStartCached = [NSDate timeIntervalSinceReferenceDate];
        
        [self.sequence getLocationsAsync:^(NSArray *array) {
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

- (void)testLock
{
    XCTAssertFalse([self.sequence isLocked]);
    
    [self.sequence lock];
    
    XCTAssertTrue([self.sequence isLocked]);
    
    [self.sequence unlock];
    
    XCTAssertFalse([self.sequence isLocked]);
}

- (void)testDeleteImage
{
    NSData* imageData = [self createImageData];
    
    NSArray* images = [self.sequence getImages];
    XCTAssertEqual(images.count, 0);
    
    [self.sequence addImageWithData:imageData date:nil location:nil];
    images = [self.sequence getImages];
    XCTAssertEqual(images.count, 1);
    
    [self.sequence deleteImage:images.firstObject];
    images = [self.sequence getImages];
    XCTAssertEqual(images.count, 0);
    
    [self.sequence deleteImage:nil];
    images = [self.sequence getImages];
    XCTAssertEqual(images.count, 0);
}

- (void)testDeleteAllImages
{
    // There should be no images
    NSArray* images = [self.sequence getImages];
    XCTAssertNotNil(images);
    XCTAssert(images.count == 0);
    
    // Add test data
    NSData* imageData = [self createImageData];
    int nbrImages = arc4random()%100;
    for (int i = 0; i < nbrImages; i++)
    {
        [self.sequence addImageWithData:imageData date:nil location:nil];
    }
    
    // There should now be nbrImages images
    images = [self.sequence getImages];
    XCTAssert(images.count == nbrImages);
    
    // Delete all images
    [self.sequence deleteAllImages];
    
    // There should be no images
    images = [self.sequence getImages];
    XCTAssert(images.count == 0);
}

- (void)testHeadingWithoutCompassValues
{
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:250];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    [self.sequence addLocation:a];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:750];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50.1, 50.1) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:b.timestamp];
    [self.sequence addLocation:b];
    
    MAPLocation* location1 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:0]];
    MAPLocation* location2 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:250]];
    MAPLocation* location3 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:500]];
    MAPLocation* location4 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:750]];
    MAPLocation* location5 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:1000]];
    
    NSNumber* correctHeading = @45;
    MAPLocation* testLoction = nil;
    
    testLoction = location1;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location2;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location3;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location4;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location5;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
}

- (void)testHeadingWithoutCompassValues2
{
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:250];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    [self.sequence addLocation:a];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:750];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50.1, 50.1) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:b.timestamp];
    [self.sequence addLocation:b];
    
    MAPLocation* location1 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:0]];
    MAPLocation* location2 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:250]];
    MAPLocation* location3 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:500]];
    MAPLocation* location4 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:750]];
    MAPLocation* location5 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:1000]];
    
    NSNumber* correctHeading = @45;
    MAPLocation* testLoction = nil;
    
    testLoction = location1;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location2;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location3;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location4;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
    
    testLoction = location5;
    XCTAssert(testLoction.magneticHeading.doubleValue-correctHeading.doubleValue < 0.01);
    XCTAssert(testLoction.trueHeading.doubleValue-correctHeading.doubleValue < 0.01);
}

- (void)testHeadingWithCompassValues
{
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:250];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    a.magneticHeading = @0;
    a.trueHeading = @0;
    [self.sequence addLocation:a];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:750];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(51, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:b.timestamp];
    b.magneticHeading = @90;
    b.trueHeading = @90;
    [self.sequence addLocation:b];
    
    MAPLocation* location1 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:0]];
    MAPLocation* location2 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:250]];
    MAPLocation* location3 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:500]];
    MAPLocation* location4 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:750]];
    MAPLocation* location5 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:1000]];
    
    NSNumber* correctHeading = nil;
    MAPLocation* testLoction = nil;
    
    testLoction = location1;
    correctHeading = @0;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location2;
    correctHeading = @0;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location3;
    correctHeading = @45;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location4;
    correctHeading = @90;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location5;
    correctHeading = @90;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
}

- (void)testHeadingWithCompassValues2
{
    self.sequence.directionOffset = @0;
    
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:250];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    a.magneticHeading = @0;
    a.trueHeading = @0;
    [self.sequence addLocation:a];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:750];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(51, 51) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:b.timestamp];
    b.magneticHeading = @90;
    b.trueHeading = @90;
    [self.sequence addLocation:b];
    
    MAPLocation* c = [[MAPLocation alloc] init];
    c.timestamp = [NSDate dateWithTimeIntervalSince1970:1000];
    c.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:c.timestamp];
    c.magneticHeading = @270;
    c.trueHeading = @270;
    [self.sequence addLocation:c];
    
    MAPLocation* location1 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:0]];
    MAPLocation* location2 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:250]];
    MAPLocation* location3 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:800]];
    
    NSNumber* correctHeading = nil;
    MAPLocation* testLoction = nil;
    
    // Verified using http://instantglobe.com/CRANES/GeoCoordTool.html
    
    testLoction = location1;
    correctHeading = @32;
    XCTAssertEqual(testLoction.magneticHeading.intValue, correctHeading.intValue);
    XCTAssertEqual(testLoction.trueHeading.intValue, correctHeading.intValue);
    
    testLoction = location2;
    correctHeading = @32;
    XCTAssertEqual(testLoction.magneticHeading.intValue, correctHeading.intValue);
    XCTAssertEqual(testLoction.trueHeading.intValue, correctHeading.intValue);
    
    testLoction = location3;
    correctHeading = @212;
    XCTAssertEqual(testLoction.magneticHeading.intValue, correctHeading.intValue);
    XCTAssertEqual(testLoction.trueHeading.intValue, correctHeading.intValue);
}

- (void)testImageHeadingWithCompassValues
{
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:250];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    a.magneticHeading = @0;
    a.trueHeading = @0;
    [self.sequence addLocation:a];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:750];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 51) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:b.timestamp];
    b.magneticHeading = @180;
    b.trueHeading = @180;
    [self.sequence addLocation:b];
    
    MAPLocation* c = [[MAPLocation alloc] init];
    c.timestamp = [NSDate dateWithTimeIntervalSince1970:1000];
    c.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:c.timestamp];
    c.magneticHeading = @270;
    c.trueHeading = @270;
    [self.sequence addLocation:c];
    
    [self.sequence addImageWithData:[self createImageData] date:[NSDate dateWithTimeIntervalSince1970:0] location:nil];
    [self.sequence addImageWithData:[self createImageData] date:[NSDate dateWithTimeIntervalSince1970:250] location:nil];
    [self.sequence addImageWithData:[self createImageData] date:[NSDate dateWithTimeIntervalSince1970:500] location:nil];
    [self.sequence addImageWithData:[self createImageData] date:[NSDate dateWithTimeIntervalSince1970:750] location:nil];
    [self.sequence addImageWithData:[self createImageData] date:[NSDate dateWithTimeIntervalSince1970:1000] location:nil];
    
    self.expectationImagesProcessed = [self expectationWithDescription:@"Processed images"];
    
    // Process images
    
    [MAPUploadManager sharedManager].delegate = self;
    [[MAPUploadManager sharedManager] processSequences:@[self.sequence] forceReprocessing:YES];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
            [MAPUploadManager sharedManager].delegate = nil;
        }
    }];
    
    [MAPUploadManager sharedManager].delegate = nil;
    
    // Images are processed now
    
    NSArray* images = [self.sequence getImages];
    
    int correctHeading = -1;
    NSNumber* magneticHeading = nil;
    NSNumber* trueHeading = nil;
    NSDictionary* heading = nil;
    
    correctHeading = 0;
    heading = [self getCompassHeadingFromImage:images[0]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = 0;
    heading = [self getCompassHeadingFromImage:images[1]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = 90;
    heading = [self getCompassHeadingFromImage:images[2]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = 180;
    heading = [self getCompassHeadingFromImage:images[3]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = 270; // 270+90 = 360 = 0
    heading = [self getCompassHeadingFromImage:images[4]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
}

- (void)testImageHeadingWithCompassValuesRandom
{
    int correctHeading = arc4random()%360;
    
    for (int i = 0; i < arc4random()%100; i++)
    {
        MAPLocation* a = [[MAPLocation alloc] init];
        a.timestamp = [NSDate dateWithTimeIntervalSince1970:arc4random()%10*i];
        a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50+i*0.1, 50+i*0.1) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
        a.magneticHeading = [NSNumber numberWithInt:correctHeading];
        a.trueHeading = [NSNumber numberWithInt:correctHeading];
        [self.sequence addLocation:a];
    }
    
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test-image" ofType:@"jpg"];
    NSData* imageData = [NSData dataWithContentsOfFile:path];
    
    for (int i = 0; i < arc4random()%25; i++)
    {
        [self.sequence addImageWithData:imageData date:[NSDate dateWithTimeIntervalSince1970:arc4random()%10*i] location:nil];
    }
    
    self.expectationImagesProcessed = [self expectationWithDescription:@"Processed images"];
    
    // Process images
    
    [MAPUploadManager sharedManager].delegate = self;
    [[MAPUploadManager sharedManager] processSequences:@[self.sequence] forceReprocessing:YES];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
            [MAPUploadManager sharedManager].delegate = nil;
        }
    }];
    
    [MAPUploadManager sharedManager].delegate = nil;
    
    // Images are processed now
    
    NSArray* images = [self.sequence getImages];
    
    for (MAPImage* image in images)
    {
        NSDictionary* heading = [self getCompassHeadingFromImage:image];
        NSNumber* magneticHeading = heading[kMAPMagneticHeading];
        NSNumber* trueHeading = heading[kMAPTrueHeading];
        XCTAssert(magneticHeading.intValue == correctHeading);
        XCTAssert(trueHeading.intValue == correctHeading);
    }
}

- (void)testImageHeadingWithCompassValuesCircle
{
    int divider = 36;
    
    for (int i = 0; i <= 360/divider; i++)
    {
        float x = 50+10*cosf(i*M_PI/180.0);
        float y = 50+10*sinf(i*M_PI/180.0);
        
        MAPLocation* a = [[MAPLocation alloc] init];
        a.timestamp = [NSDate dateWithTimeIntervalSince1970:100*i];
        a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(x, y) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
        a.magneticHeading = [NSNumber numberWithFloat:i*360/divider];
        a.trueHeading = [NSNumber numberWithFloat:i*360/divider];
        [self.sequence addLocation:a];
        
        NSLog(@"%f", a.magneticHeading.floatValue);
    }
    
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test-image" ofType:@"jpg"];
    NSData* imageData = [NSData dataWithContentsOfFile:path];
    
    for (int i = 0; i <= 360/divider; i++)
    {
        [self.sequence addImageWithData:imageData date:[NSDate dateWithTimeIntervalSince1970:100*i] location:nil];
    }
    
    self.expectationImagesProcessed = [self expectationWithDescription:@"Processed images"];
    
    // Process images
    
    [MAPUploadManager sharedManager].delegate = self;
    [[MAPUploadManager sharedManager] processSequences:@[self.sequence] forceReprocessing:YES];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
            [MAPUploadManager sharedManager].delegate = nil;
        }
    }];
    
    [MAPUploadManager sharedManager].delegate = nil;
    
    // Images are processed now
    
    NSArray* images = [self.sequence getImages];
    
    int correct = 0;
    
    for (MAPImage* image in images)
    {
        NSDictionary* heading = [self getCompassHeadingFromImage:image];
        NSNumber* magneticHeading = heading[kMAPMagneticHeading];
        NSNumber* trueHeading = heading[kMAPTrueHeading];
        
        XCTAssert(magneticHeading.intValue == correct);
        XCTAssert(trueHeading.intValue == correct);
        
        NSLog(@"%f", magneticHeading.floatValue);
        
        correct += 360/divider;
        if (correct > 360) correct -= 360;
    }
}

- (void)testImageHeadingWithForwardValuesCircle
{
    int divider = 36;
    
    for (int i = 0; i <= 360/divider; i++)
    {
        float x = 50+10*cosf(i*M_PI/180.0);
        float y = 50+10*sinf(i*M_PI/180.0);
        
        MAPLocation* a = [[MAPLocation alloc] init];
        a.timestamp = [NSDate dateWithTimeIntervalSince1970:100*i];
        a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(x, y) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
        a.magneticHeading = [NSNumber numberWithFloat:i*360/divider];
        a.trueHeading = [NSNumber numberWithFloat:i*360/divider];
        [self.sequence addLocation:a];
        
        NSLog(@"%f", a.magneticHeading.floatValue);
    }
    
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test-image" ofType:@"jpg"];
    NSData* imageData = [NSData dataWithContentsOfFile:path];
    
    for (int i = 0; i <= 360/divider; i++)
    {
        [self.sequence addImageWithData:imageData date:[NSDate dateWithTimeIntervalSince1970:100*i] location:nil];
    }
    
    self.expectationImagesProcessed = [self expectationWithDescription:@"Processed images"];
    
    // Process images
    
    [MAPUploadManager sharedManager].delegate = self;
    [[MAPUploadManager sharedManager] processSequences:@[self.sequence] forceReprocessing:YES];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
            [MAPUploadManager sharedManager].delegate = nil;
        }
    }];
    
    [MAPUploadManager sharedManager].delegate = nil;
    
    // Images are processed now
    
    NSArray* images = [self.sequence getImages];
    
    int correct = 0;
    
    for (MAPImage* image in images)
    {
        NSDictionary* heading = [self getCompassHeadingFromImage:image];
        NSNumber* magneticHeading = heading[kMAPMagneticHeading];
        NSNumber* trueHeading = heading[kMAPTrueHeading];
        
        XCTAssert(magneticHeading.intValue == correct);
        XCTAssert(trueHeading.intValue == correct);
        
        
        correct += 360/divider;
        if (correct > 360) correct -= 360;
    }
}
    
- (void)processingFinished:(MAPUploadManager *)uploadManager status:(MAPUploadManagerStatus *)status
{
    [self.expectationImagesProcessed fulfill];
}

- (void)testNullIsland
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Testing for Null Island"];
    
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"mapbox-test" ofType:@"gpx"];
    
    __weak MAPSequenceTests* weakSelf = self;
    
    [weakSelf.sequence addGpx:path done:^{
        
        MAPLocation* nullIsland = [[MAPLocation alloc] init];
        nullIsland.location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        [weakSelf.sequence addLocation:nullIsland]; // This should not be accepted
        
        [weakSelf.sequence getLocationsAsync:^(NSArray *array) {
            
            MAPLocation* first = array.firstObject;
            MAPLocation* last = array.lastObject;
            MAPLocation* errorLocation = nil;
            
            // Test track points
            for (MAPLocation* location in array)
            {
                if (!CLLocationCoordinate2DIsValid(location.location.coordinate) ||
                    fabs(location.location.coordinate.latitude) < DBL_EPSILON ||
                    fabs(location.location.coordinate.longitude) < DBL_EPSILON)
                {
                    errorLocation = location;
                    break;
                }
            }
            
            XCTAssertNil(errorLocation);
            
            // Test interpolation
            
            double samples = arc4random()%1000;
            NSTimeInterval interval = (last.timestamp.timeIntervalSince1970-first.timestamp.timeIntervalSince1970)/samples;
            
            for (int i = 0; i < samples; i++)
            {
                NSDate* sampleDate = [[NSDate alloc] initWithTimeInterval:i*interval sinceDate:first.timestamp];
                
                MAPLocation* location = [weakSelf.sequence locationForDate:sampleDate];
                
                if (!CLLocationCoordinate2DIsValid(location.location.coordinate) ||
                    fabs(location.location.coordinate.latitude) < DBL_EPSILON ||
                    fabs(location.location.coordinate.longitude) < DBL_EPSILON)
                {
                    errorLocation = location;
                    break;
                }
            }
            
            XCTAssertNil(errorLocation);
            
            [expectation fulfill];
            
        }];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:120 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

- (void)testImageProcessing
{
    [[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:MAPILLARY_CURRENT_USER_KEY];
    
    NSData* imageData = [self createImageData];
    MAPLocation* location = [[MAPLocation alloc] init];
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];

    [self.sequence addImageWithData:imageData date:nil location:nil];
    [self.sequence addLocation:location];
    
    MAPImage* image = [[self.sequence getImages] firstObject];
    
    XCTAssertFalse([MAPExifTools imageHasMapillaryTags:image]);
    
    [self.sequence processImage:image forceReprocessing:YES];

    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
}

- (void)testImageProcessingRealtimeWithoutLocation
{
    // Same as testImageProcessing but without the separate processing step
    
    [[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:MAPILLARY_CURRENT_USER_KEY];
        
    NSData* imageData = [self createImageData];
    MAPLocation* location = [[MAPLocation alloc] init];
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    // Image 1, no location, should not have tags after it's added
    [self.sequence addImageWithData:imageData date:nil location:nil];
    MAPImage* image = [[self.sequence getImages] firstObject];
    XCTAssertFalse([MAPExifTools imageHasMapillaryTags:image]);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    XCTAssertFalse([MAPExifTools imageHasMapillaryTags:image]);
    
    // Image 2, with location, should have tags after it's added
    imageData = [self createImageData];
    [self.sequence addImageWithData:imageData date:nil location:location];
    image = [[self.sequence getImages] lastObject];
    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
}

- (void)testImageProcessingRealtimeWithLocation
{
    // Same as testImageProcessing but without the separate processing step
    
    [[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:MAPILLARY_CURRENT_USER_KEY];
        
    NSData* imageData = [self createImageData];
    MAPLocation* location = [[MAPLocation alloc] init];
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    // Image 1, with location, should have tags after it's added
    [self.sequence addImageWithData:imageData date:nil location:location];
    MAPImage* image = [[self.sequence getImages] firstObject];
    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    // Image 2, with location, should have tags after it's added
    imageData = [self createImageData];
    [self.sequence addImageWithData:imageData date:nil location:location];
    image = [[self.sequence getImages] lastObject];
    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
}

- (void)testImageProcessingRealtimeWithLocationAndHeading
{
    // Same as testImageProcessing but without the separate processing step
    
    [[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:MAPILLARY_CURRENT_USER_KEY];
        
    NSData* imageData = [self createImageData];
    MAPLocation* location = [[MAPLocation alloc] init];
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    
    // Image 1
    location.magneticHeading = @10;
    location.trueHeading = @20;
    [self.sequence addImageWithData:imageData date:nil location:location];
    MAPImage* image = [[self.sequence getImages] firstObject];
    NSDictionary* hedingDict = [self getCompassHeadingFromImage:image];
    NSNumber* magneticHeading = hedingDict[kMAPMagneticHeading];
    NSNumber* trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(location.magneticHeading.intValue, magneticHeading.intValue);
    XCTAssertEqual(location.trueHeading.intValue, trueHeading.intValue);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    hedingDict = [self getCompassHeadingFromImage:image];
    magneticHeading = hedingDict[kMAPMagneticHeading];
    trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(location.magneticHeading.intValue, magneticHeading.intValue);
    XCTAssertEqual(location.trueHeading.intValue, trueHeading.intValue);
    
    // Image 2
    imageData = [self createImageData];
    location.magneticHeading = @20;
    location.trueHeading = @30;
    [self.sequence addImageWithData:imageData date:nil location:location];
    image = [[self.sequence getImages] lastObject];
    hedingDict = [self getCompassHeadingFromImage:image];
    magneticHeading = hedingDict[kMAPMagneticHeading];
    trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(location.magneticHeading.intValue, magneticHeading.intValue);
    XCTAssertEqual(location.trueHeading.intValue, trueHeading.intValue);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    hedingDict = [self getCompassHeadingFromImage:image];
    magneticHeading = hedingDict[kMAPMagneticHeading];
    trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(location.magneticHeading.intValue, magneticHeading.intValue);
    XCTAssertEqual(location.trueHeading.intValue, trueHeading.intValue);
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
}

- (void)testImageProcessingRealtimeWithLocationAndHeadingWithDirectionSetForward
{
    [[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:MAPILLARY_CURRENT_USER_KEY];
    
    self.sequence.directionOffset = @0;
        
    NSData* imageData = [self createImageData];
    MAPLocation* location = [[MAPLocation alloc] init];
    
    
    // Image 1, since we are "looking at next", not possible to add compass angle at this point
    location.magneticHeading = @10;
    location.trueHeading = @20;
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    [self.sequence addImageWithData:imageData date:nil location:location];
    MAPImage* image = [[self.sequence getImages] firstObject];
    NSDictionary* hedingDict = [self getCompassHeadingFromImage:image];
    XCTAssertNil(hedingDict);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    hedingDict = [self getCompassHeadingFromImage:image];
    XCTAssertNil(hedingDict);
    
    // Image 2
    imageData = [self createImageData];
    location.magneticHeading = @20;
    location.trueHeading = @30;
    location.location = [[CLLocation alloc] initWithLatitude:51 longitude:51];
    [self.sequence addImageWithData:imageData date:nil location:location];
    image = [[self.sequence getImages] lastObject];
    hedingDict = [self getCompassHeadingFromImage:image];
    NSNumber* magneticHeading = hedingDict[kMAPMagneticHeading];
    NSNumber* trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(magneticHeading.intValue, 32);
    XCTAssertEqual(trueHeading.intValue, 32);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    hedingDict = [self getCompassHeadingFromImage:image];
    magneticHeading = hedingDict[kMAPMagneticHeading];
    trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(magneticHeading.intValue, 32);
    XCTAssertEqual(trueHeading.intValue, 32);
    
    // Image 3
    imageData = [self createImageData];
    location.magneticHeading = @15;
    location.trueHeading = @45;
    location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    [self.sequence addImageWithData:imageData date:nil location:location];
    image = [[self.sequence getImages] lastObject];
    hedingDict = [self getCompassHeadingFromImage:image];
    magneticHeading = hedingDict[kMAPMagneticHeading];
    trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(magneticHeading.intValue, 212);
    XCTAssertEqual(trueHeading.intValue, 212);
    
    image = [[MAPImage alloc] initWithPath:image.imagePath];
    hedingDict = [self getCompassHeadingFromImage:image];
    magneticHeading = hedingDict[kMAPMagneticHeading];
    trueHeading = hedingDict[kMAPTrueHeading];
    XCTAssertEqual(magneticHeading.intValue, 212);
    XCTAssertEqual(trueHeading.intValue, 212);
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
}

- (void)testTimeOffset
{
    NSDate* date1 = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate* date2 = [NSDate dateWithTimeIntervalSince1970:250];
    NSDate* date3 = [NSDate dateWithTimeIntervalSince1970:500];
    NSDate* date4 = [NSDate dateWithTimeIntervalSince1970:750];
    NSDate* date5 = [NSDate dateWithTimeIntervalSince1970:1000];
    
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
        location.timestamp = date2;
        [self.sequence addLocation:location];
    }
    
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:55 longitude:55];
        location.timestamp = date4;
        [self.sequence addLocation:location];
    }
    
    // Test with no offset
    self.sequence.timeOffset = nil;
    
    MAPLocation* location1 = [self.sequence locationForDate:date1];
    MAPLocation* location2 = [self.sequence locationForDate:date2];
    MAPLocation* location3 = [self.sequence locationForDate:date3];
    MAPLocation* location4 = [self.sequence locationForDate:date4];
    MAPLocation* location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.location.coordinate.latitude, 50);
    XCTAssertEqual(location1.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location2.location.coordinate.latitude, 50);
    XCTAssertEqual(location2.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location3.location.coordinate.latitude, 52.5);
    XCTAssertEqual(location3.location.coordinate.longitude, 52.5);
    
    XCTAssertEqual(location4.location.coordinate.latitude, 55);
    XCTAssertEqual(location4.location.coordinate.longitude, 55);
    
    XCTAssertEqual(location5.location.coordinate.latitude, 55);
    XCTAssertEqual(location5.location.coordinate.longitude, 55);
    
    // Test with 0 offset
    self.sequence.timeOffset = @0;
        
    location1 = [self.sequence locationForDate:date1];
    location2 = [self.sequence locationForDate:date2];
    location3 = [self.sequence locationForDate:date3];
    location4 = [self.sequence locationForDate:date4];
    location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.location.coordinate.latitude, 50);
    XCTAssertEqual(location1.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location2.location.coordinate.latitude, 50);
    XCTAssertEqual(location2.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location3.location.coordinate.latitude, 52.5);
    XCTAssertEqual(location3.location.coordinate.longitude, 52.5);
    
    XCTAssertEqual(location4.location.coordinate.latitude, 55);
    XCTAssertEqual(location4.location.coordinate.longitude, 55);
    
    XCTAssertEqual(location5.location.coordinate.latitude, 55);
    XCTAssertEqual(location5.location.coordinate.longitude, 55);
        
    // Test with positive offset
    self.sequence.timeOffset = @250;
    
    location1 = [self.sequence locationForDate:date1];
    location2 = [self.sequence locationForDate:date2];
    location3 = [self.sequence locationForDate:date3];
    location4 = [self.sequence locationForDate:date4];
    location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.location.coordinate.latitude, 50);
    XCTAssertEqual(location1.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location2.location.coordinate.latitude, 52.5);
    XCTAssertEqual(location2.location.coordinate.longitude, 52.5);
    
    XCTAssertEqual(location3.location.coordinate.latitude, 55);
    XCTAssertEqual(location3.location.coordinate.longitude, 55);
    
    XCTAssertEqual(location4.location.coordinate.latitude, 55);
    XCTAssertEqual(location4.location.coordinate.longitude, 55);
    
    XCTAssertEqual(location5.location.coordinate.latitude, 55);
    XCTAssertEqual(location5.location.coordinate.longitude, 55);
    
    
    // Test with negative offset
    self.sequence.timeOffset = [NSNumber numberWithInt:-250];
    
    location1 = [self.sequence locationForDate:date1];
    location2 = [self.sequence locationForDate:date2];
    location3 = [self.sequence locationForDate:date3];
    location4 = [self.sequence locationForDate:date4];
    location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.location.coordinate.latitude, 50);
    XCTAssertEqual(location1.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location2.location.coordinate.latitude, 50);
    XCTAssertEqual(location2.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location3.location.coordinate.latitude, 50);
    XCTAssertEqual(location3.location.coordinate.longitude, 50);
    
    XCTAssertEqual(location4.location.coordinate.latitude, 52.5);
    XCTAssertEqual(location4.location.coordinate.longitude, 52.5);
    
    XCTAssertEqual(location5.location.coordinate.latitude, 55);
    XCTAssertEqual(location5.location.coordinate.longitude, 55);
}

- (void)testDirectionOffset
{
    NSDate* date1 = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate* date2 = [NSDate dateWithTimeIntervalSince1970:250];
    NSDate* date3 = [NSDate dateWithTimeIntervalSince1970:500];
    NSDate* date4 = [NSDate dateWithTimeIntervalSince1970:750];
    NSDate* date5 = [NSDate dateWithTimeIntervalSince1970:1000];
    
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
        location.trueHeading = [NSNumber numberWithDouble:0.0];
        location.magneticHeading = [NSNumber numberWithDouble:0.0];
        location.timestamp = date2;
        [self.sequence addLocation:location];
    }
    
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:50.01 longitude:50.01];
        location.trueHeading = [NSNumber numberWithDouble:10.0];
        location.magneticHeading = [NSNumber numberWithDouble:15.0];
        location.timestamp = date4;
        [self.sequence addLocation:location];
    }
    
    // Test with no offset
    self.sequence.directionOffset = nil;
    
    MAPLocation* location1 = [self.sequence locationForDate:date1];
    MAPLocation* location2 = [self.sequence locationForDate:date2];
    MAPLocation* location3 = [self.sequence locationForDate:date3];
    MAPLocation* location4 = [self.sequence locationForDate:date4];
    MAPLocation* location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.trueHeading.floatValue, 0.0f);
    XCTAssertEqual(location1.magneticHeading.floatValue, 0.0f);
    
    XCTAssertEqual(location2.trueHeading.floatValue, 0.0f);
    XCTAssertEqual(location2.magneticHeading.floatValue, 0.0f);
    
    XCTAssertEqual(location3.trueHeading.floatValue, 5.0f);
    XCTAssertEqual(location3.magneticHeading.floatValue, 7.5f);
    
    XCTAssertEqual(location4.trueHeading.intValue, 10.0f);
    XCTAssertEqual(location4.magneticHeading.intValue, 15.0f);
    
    XCTAssertEqual(location5.trueHeading.floatValue, 10.0f);
    XCTAssertEqual(location5.magneticHeading.floatValue, 15.0f);
    
    // Test with 0 offset
    self.sequence.directionOffset = @0;
    
    location1 = [self.sequence locationForDate:date1];
    location2 = [self.sequence locationForDate:date2];
    location3 = [self.sequence locationForDate:date3];
    location4 = [self.sequence locationForDate:date4];
    location5 = [self.sequence locationForDate:date5];
    
    XCTAssert(location1.trueHeading.floatValue-44.091251 < 0.01);
    XCTAssert(location1.magneticHeading.floatValue-44.091251 < 0.01);
    
    XCTAssert(location2.trueHeading.floatValue-44.091251 < 0.01);
    XCTAssert(location2.magneticHeading.floatValue-44.091251 < 0.01);
    
    XCTAssert(location3.trueHeading.floatValue-44.091251 < 0.01);
    XCTAssert(location3.magneticHeading.floatValue-44.091251 < 0.01);
    
    XCTAssert(location4.trueHeading.floatValue-44.091251 < 0.01);
    XCTAssert(location4.magneticHeading.floatValue-44.091251 < 0.01);
    
    XCTAssert(location5.trueHeading.floatValue-44.091251 < 0.01);
    XCTAssert(location5.magneticHeading.floatValue-44.091251 < 0.01);
    
    // Test with positive offset
    self.sequence.directionOffset = @10;
    
    location1 = [self.sequence locationForDate:date1];
    location2 = [self.sequence locationForDate:date2];
    location3 = [self.sequence locationForDate:date3];
    location4 = [self.sequence locationForDate:date4];
    location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.trueHeading.floatValue, 10.0f);
    XCTAssertEqual(location1.magneticHeading.floatValue, 10.0f);
    
    XCTAssertEqual(location2.trueHeading.floatValue, 10.0f);
    XCTAssertEqual(location2.magneticHeading.floatValue, 10.0f);
    
    XCTAssertEqual(location3.trueHeading.floatValue, 15.0f);
    XCTAssertEqual(location3.magneticHeading.floatValue, 17.5f);
    
    XCTAssertEqual(location4.trueHeading.floatValue, 20.0f);
    XCTAssertEqual(location4.magneticHeading.floatValue, 25.0f);
    
    XCTAssertEqual(location5.trueHeading.floatValue, 20.0f);
    XCTAssertEqual(location5.magneticHeading.floatValue, 25.0f);
    
    
    // Test with negative offset
    self.sequence.directionOffset = @-10;
    
    location1 = [self.sequence locationForDate:date1];
    location2 = [self.sequence locationForDate:date2];
    location3 = [self.sequence locationForDate:date3];
    location4 = [self.sequence locationForDate:date4];
    location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.trueHeading.floatValue, 350.0f);
    XCTAssertEqual(location1.magneticHeading.floatValue, 350.0f);
    
    XCTAssertEqual(location2.trueHeading.floatValue, 350.0f);
    XCTAssertEqual(location2.magneticHeading.floatValue, 350.0f);
    
    XCTAssertEqual(location3.trueHeading.floatValue, 355.0f);
    XCTAssertEqual(location3.magneticHeading.floatValue, 357.5f);
    
    XCTAssertEqual(location4.trueHeading.floatValue, 0.0f);
    XCTAssertEqual(location4.magneticHeading.floatValue, 5.0f);
    
    XCTAssertEqual(location5.trueHeading.floatValue, 0.0f);
    XCTAssertEqual(location5.magneticHeading.floatValue, 5.0f);
    
    // Test with big direction offset
    self.sequence.directionOffset = @540; // 360+180
    
    location1 = [self.sequence locationForDate:date1];
    location2 = [self.sequence locationForDate:date2];
    location3 = [self.sequence locationForDate:date3];
    location4 = [self.sequence locationForDate:date4];
    location5 = [self.sequence locationForDate:date5];
    
    XCTAssertEqual(location1.trueHeading.floatValue, 180.0f);
    XCTAssertEqual(location1.magneticHeading.floatValue, 180.0f);
    
    XCTAssertEqual(location2.trueHeading.floatValue, 180.0f);
    XCTAssertEqual(location2.magneticHeading.floatValue, 180.0f);
    
    XCTAssertEqual(location3.trueHeading.floatValue, 185.0f);
    XCTAssertEqual(location3.magneticHeading.floatValue, 187.5f);
    
    XCTAssertEqual(location4.trueHeading.floatValue, 190.0f);
    XCTAssertEqual(location4.magneticHeading.floatValue, 195.0f);
    
    XCTAssertEqual(location5.trueHeading.floatValue, 190.0f);
    XCTAssertEqual(location5.magneticHeading.floatValue, 195.0f);
}

- (void)testSavePropertyChanges
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Changed properties should be saved"];
    
    self.sequence.directionOffset = @45;
    self.sequence.sequenceDate = [NSDate dateWithTimeIntervalSince1970:1000];
    
    [self.sequence savePropertyChanges:^{
        
        NSString* path = self.sequence.path;
        
        MAPSequence* sequence2 = [[MAPSequence alloc] initWithPath:path parseGpx:YES];
        
        XCTAssertEqual(sequence2.directionOffset.intValue, 45);
        XCTAssertEqual(sequence2.sequenceDate.timeIntervalSince1970, 1000);
        
        [MAPFileManager deleteSequence:sequence2];
        
        [expectation fulfill];
    
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:120 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

- (void)testAddDuplicatesSameCoordinate
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Sequence should not contain duplicates"];
    
    MAPLocation* l1 = [[MAPLocation alloc] init];
    MAPLocation* l2 = [[MAPLocation alloc] init];
    l1.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:50 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:10 timestamp:[NSDate date]];
    l2.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:50 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:10 timestamp:[NSDate date]];
    
    [self.sequence addLocation:l1];
    [self.sequence addLocation:l2];
    
    [self.sequence getLocationsAsync:^(NSArray *locations) {
        
        XCTAssertEqual(locations.count, 1);
        
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:120 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

- (void)testAddDuplicatesAlmostSameCoordinate
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Sequence should not contain duplicates"];
    
    MAPLocation* l1 = [[MAPLocation alloc] init];
    MAPLocation* l2 = [[MAPLocation alloc] init];
    l1.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:50 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:10 timestamp:[NSDate date]];
    l2.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50.000001, 50.000001) altitude:50 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:10 timestamp:[NSDate date]]; // < 10 cm
    
    [self.sequence addLocation:l1];
    [self.sequence addLocation:l2];
    
    [self.sequence getLocationsAsync:^(NSArray *locations) {
        
        XCTAssertEqual(locations.count, 1);
        
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:120 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

- (void)testAddDuplicatesSameCourse
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Sequence should not contain duplicates"];
    
    MAPLocation* l1 = [[MAPLocation alloc] init];
    MAPLocation* l2 = [[MAPLocation alloc] init];
    l1.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:50 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:10 timestamp:[NSDate date]];
    l2.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:50 horizontalAccuracy:0 verticalAccuracy:30 course:0 speed:10 timestamp:[NSDate date]];
    
    [self.sequence addLocation:l1];
    [self.sequence addLocation:l2];
    
    [self.sequence getLocationsAsync:^(NSArray *locations) {
        
        XCTAssertEqual(locations.count, 1);
        
        [expectation fulfill];
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:120 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
}

#pragma mark - Utils

- (NSData*)createImageData
{
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test-image" ofType:@"jpg"];
    return [NSData dataWithContentsOfFile:path];
}

- (NSDictionary*)getCompassHeadingFromImage:(MAPImage*)image
{
    NSDictionary* compassHeading = nil;
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:image.imagePath], NULL);
    
    if (imageSource)
    {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        NSDictionary* propertiesDictionary = (NSDictionary *)CFBridgingRelease(properties);
        NSDictionary* TIFFDictionary = [propertiesDictionary objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        
        if (TIFFDictionary)
        {
            NSString* description = [TIFFDictionary objectForKey:(NSString *)kCGImagePropertyTIFFImageDescription];
            
            if (description)
            {
                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:[description dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                compassHeading = json[kMAPCompassHeading];
            }
        }
        
        CFRelease(imageSource);
    }
    
    return compassHeading;
}

@end
