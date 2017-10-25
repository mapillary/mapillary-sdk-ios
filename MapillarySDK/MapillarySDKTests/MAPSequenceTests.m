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

@end

@implementation MAPSequenceTests

- (void)setUp
{
    [super setUp];
    
    self.device = [[MAPDevice alloc] init];
    self.device.name = @"iPhone7,2";
    self.device.make = @"Apple";
    self.device.model = @"iPhone 6";
}

- (void)tearDown
{
    self.device = nil;
    
    [super tearDown];
}

- (void)testSanity
{
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:self.device];
    
    BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:sequence.path isDirectory:nil];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[sequence.path stringByAppendingPathComponent:@"sequence.gpx"] isDirectory:nil];
    
    XCTAssertNotNil(sequence.sequenceDate);
    XCTAssertNotNil(sequence.sequenceKey);
    XCTAssertNotNil(sequence.device);
    XCTAssertNotNil(sequence.project);
    XCTAssertNotNil(sequence.path);
    XCTAssertNotNil([sequence listImages]);
    
    XCTAssert(sequence.timeOffset == 0);
    XCTAssert(sequence.directionOffset == -1);
    XCTAssert([sequence listImages].count == 0);
    
    XCTAssertTrue(directoryExists);
    XCTAssertTrue(fileExists);
    
    [MAPFileManager deleteSequence:sequence];
    
    directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:sequence.path isDirectory:nil];
    XCTAssertFalse(directoryExists);
}

- (void)testAddImagesFromData
{
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:self.device];
    
    // There should be no images
    NSArray* images = [sequence listImages];
    XCTAssertNotNil(images);
    XCTAssert(images.count == 0);
    
    // Test with invalid data
    NSData* imageData = nil;
    XCTAssertThrows([sequence addImageWithData:imageData date:nil location:nil]);
    
    // Test with valid data
    imageData = [self createImageData];
    int nbrImages = arc4random()%100;
    for (int i = 0; i < nbrImages; i++)
    {
        XCTAssertNoThrow([sequence addImageWithData:imageData date:nil location:nil]);
    }

    // There should now be nbrImages images
    images = [sequence listImages];
    XCTAssert(images.count == nbrImages);
    
    // Cleanup
    [MAPFileManager deleteSequence:sequence];
}

- (void)testAddImagesFromFile
{
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:self.device];
    
    NSString* path = [NSString stringWithFormat:@"%@/%@", [MAPInternalUtils documentsDirectory], @"temp.jpg"];
    
    NSData* imageData = [self createImageData];
    [imageData writeToFile:path atomically:YES];
    
    int nbrImages = arc4random()%100;
    for (int i = 0; i < nbrImages; i++)
    {
        XCTAssertNoThrow([sequence addImageWithPath:path date:nil location:nil]);
    }
    
    // There should now be nbrImages images
    XCTAssert([sequence listImages].count == nbrImages);
    
    // Cleanup
    [MAPFileManager deleteSequence:sequence];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testAddLocations
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Number of locations added should be the same as the number returned"];
    
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:self.device];
    
    int nbrPositions = arc4random()%1000;
    MAPLocation* location = [[MAPLocation alloc] init];
    for (int i = 0; i < nbrPositions; i++)
    {
        [sequence addLocation:location];
    }
    
    // There should now be nbrPositions locations
    
    [sequence listLocations:^(NSArray *array) {
        
         XCTAssert(array.count == nbrPositions);
        [expectation fulfill];
        
    }];
    
    // Cleanup
    [MAPFileManager deleteSequence:sequence];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        
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
