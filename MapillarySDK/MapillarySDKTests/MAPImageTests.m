//
//  MAPImageTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2018-03-06.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"
#import "MAPImage+Private.h"

@interface MAPImageTests : XCTestCase

@property NSString* testImagePath;

@end

@implementation MAPImageTests

- (void)setUp
{
    [super setUp];
    self.testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test-image" ofType:@"jpg"];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testImage
{
    MAPImage* image = [[MAPImage alloc] initWithPath:self.testImagePath];
    
    XCTAssertNotNil(image);
    XCTAssertNotNil([image loadImage]);
}

- (void)testThumbnail
{
    MAPImage* image = [[MAPImage alloc] initWithPath:self.testImagePath];
    
    XCTAssertNotNil([image thumbPath]);
    XCTAssertNotNil([image loadThumbnailImage]);
    
    // To make sure thumnail really exists
    [[NSFileManager defaultManager] removeItemAtPath:[image thumbPath] error:nil];
    image = [[MAPImage alloc] initWithPath:self.testImagePath];
    XCTAssertNotNil([image loadThumbnailImage]);
}

- (void)testLocked
{
    MAPImage* image = [[MAPImage alloc] initWithPath:self.testImagePath];
    
    XCTAssertFalse([image isLocked]);
    
    [image lock];
    
    XCTAssertTrue([image isLocked]);
    
    [image unlock];
    
    XCTAssertFalse([image isLocked]);
}

- (void)testNil
{
    MAPImage* image = [[MAPImage alloc] init];
    
    XCTAssertNotNil(image);
    XCTAssertNil([image loadImage]);
    XCTAssertNil([image thumbPath]);
    XCTAssertNil([image loadThumbnailImage]);
}

@end
