//
//  MAPExifToolsTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2018-02-14.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"
#import "MAPExifTools.h"
#import "MAPDefines.h"

@interface MAPExifToolsTests : XCTestCase

@end

@implementation MAPExifToolsTests

- (void)setUp
{
    [super setUp];
    
}

- (void)tearDown
{

    [super tearDown];
}

- (void)testHasNoMapillaryTags
{
    NSData* imageData = [self createImageData];
    
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:[MAPDevice thisDevice]];
    [sequence addImageWithData:imageData date:nil location:nil];
    
    MAPImage* image = [sequence getImages][0];

    XCTAssertFalse([MAPExifTools imageHasMapillaryTags:image]);
    
    [MAPFileManager deleteSequence:sequence];
}

- (void)testAddMapillaryTags
{
    [[NSUserDefaults standardUserDefaults] setObject:@"testuserkey" forKey:MAPILLARY_CURRENT_USER_KEY];
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:[MAPDevice thisDevice]];
    
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test-image" ofType:@"jpg"];
    NSData* imageData = [NSData dataWithContentsOfFile:path];
    
    MAPLocation* location1 = [[MAPLocation alloc] init];
    MAPLocation* location2 = [[MAPLocation alloc] init];
    location1.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    [sequence addLocation:location1];
    
    [sequence addImageWithData:imageData date:nil location:nil];
    
    location2.location = [[CLLocation alloc] initWithLatitude:60 longitude:60];
    [sequence addLocation:location2];
    
    MAPImage* image = [sequence getImages][0];
    
    [MAPExifTools addExifTagsToImage:image fromSequence:sequence];
    
    XCTAssertTrue([MAPExifTools imageHasMapillaryTags:image]);
    
    [MAPFileManager deleteSequence:sequence];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MAPILLARY_CURRENT_USER_KEY];
}

- (NSData*)createImageData
{
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 100, 100));
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    return UIImageJPEGRepresentation(image, 1);
}

@end
