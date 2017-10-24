//
//  MAPSequenceTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2017-10-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"

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
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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

- (void)testAddImages
{
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:self.device];
    
    // There should be no images
    NSArray* images = [sequence listImages];
    XCTAssertNotNil(images);
    XCTAssert(images.count == 0);
    
    // Test with invalid data
    NSData* imageData = nil;
    NSDate* imageDate = nil;
    MAPLocation* imageLocation = nil;
    XCTAssertThrows([sequence addImageWithData:imageData date:imageDate location:imageLocation]);
    
    // Test with valid data
    int nbrImages = arc4random()%100;
    for (int i = 0; i < nbrImages; i++)
    {
        imageData = [self createImageData];
        XCTAssertNoThrow([sequence addImageWithData:imageData date:imageDate location:imageLocation]);
    }

    // There should now be nbrImages images
    images = [sequence listImages];
    XCTAssert(images.count == nbrImages);
    
    // Cleanup
    [MAPFileManager deleteSequence:sequence];
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
