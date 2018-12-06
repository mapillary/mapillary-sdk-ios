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
        location.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
        [self.sequence addLocation:location];
    }
    
    // There should now be nbrPositions locations
    
    [self.sequence getLocationsAsync:^(NSArray *array) {
        
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
        
        [weakSelf.sequence getLocationsAsync:^(NSArray *array) {
            
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

- (void)testHeadingWithoutCompassValues
{
    MAPLocation* a = [[MAPLocation alloc] init];
    a.timestamp = [NSDate dateWithTimeIntervalSince1970:250];
    a.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:a.timestamp];
    [self.sequence addLocation:a];
    
    MAPLocation* b = [[MAPLocation alloc] init];
    b.timestamp = [NSDate dateWithTimeIntervalSince1970:750];
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(55, 55) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:b.timestamp];
    [self.sequence addLocation:b];
    
    MAPLocation* location1 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:0]];
    MAPLocation* location2 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:250]];
    MAPLocation* location3 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:500]];
    MAPLocation* location4 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:750]];
    MAPLocation* location5 = [self.sequence locationForDate:[NSDate dateWithTimeIntervalSince1970:1000]];
    
    NSNumber* correctHeading = @45;
    MAPLocation* testLoction = nil;
    
    testLoction = location1;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location2;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location3;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location4;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
    
    testLoction = location5;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
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
    
    MAPLocation* c = [[MAPLocation alloc] init];
    c.timestamp = [NSDate dateWithTimeIntervalSince1970:1000];
    c.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(50, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:c.timestamp];
    c.magneticHeading = @270;
    c.trueHeading = @270;
    [self.sequence addLocation:c];
    
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
    correctHeading = @270;
    XCTAssert([testLoction.magneticHeading isEqualToNumber:correctHeading]);
    XCTAssert([testLoction.trueHeading isEqualToNumber:correctHeading]);
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
    b.location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(51, 50) altitude:0 horizontalAccuracy:10 verticalAccuracy:10 timestamp:b.timestamp];
    b.magneticHeading = @90;
    b.trueHeading = @90;
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
    
    correctHeading = 0+90;
    heading = [self getCompassHeadingFromImage:images[0]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = 0+90;
    heading = [self getCompassHeadingFromImage:images[1]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = 45+90;
    heading = [self getCompassHeadingFromImage:images[2]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = 90+90;
    heading = [self getCompassHeadingFromImage:images[3]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
    
    correctHeading = (270+90) % 360;
    heading = [self getCompassHeadingFromImage:images[4]];
    magneticHeading = heading[kMAPMagneticHeading];
    trueHeading = heading[kMAPTrueHeading];
    XCTAssert(magneticHeading.intValue == correctHeading);
    XCTAssert(trueHeading.intValue == correctHeading);
}
    
- (void)processingFinished:(MAPUploadManager *)uploadManager status:(MAPUploadManagerStatus *)status
{
    [self.expectationImagesProcessed fulfill];
}

- (void)testNullIsland
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Testong for Null Island"];
    
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"daejeon" ofType:@"gpx"];
    
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
            
            double samples = 9876;
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
