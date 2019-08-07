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
#import "MAPDefines.h"

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

- (void)testCompassAngleInImage
{
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:[MAPDevice thisDevice]];
    sequence.directionOffset = @0; // Ignore compass values and use GPS instead

    MAPLocation* location1 = [[MAPLocation alloc] init];
    location1.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    location1.timestamp = [NSDate dateWithTimeIntervalSince1970:250];
    
    MAPLocation* location2 = [[MAPLocation alloc] init];
    location2.location = [[CLLocation alloc] initWithLatitude:50.01 longitude:50.01];
    location2.timestamp = [NSDate dateWithTimeIntervalSince1970:750];
    
    MAPLocation* location3 = [[MAPLocation alloc] init];
    location3.location = [[CLLocation alloc] initWithLatitude:50 longitude:50];
    location3.timestamp = [NSDate dateWithTimeIntervalSince1970:1250];
    
    NSData* data = [NSData dataWithContentsOfFile:self.testImagePath];
    
    [sequence addImageWithData:data date:location1.timestamp location:location1];
    [sequence addImageWithData:data date:location2.timestamp location:location2];
    [sequence addImageWithData:data date:location3.timestamp location:location3];
    
    NSArray* images = [sequence getImages];
    
    for (MAPImage* image in images)
    {
        [sequence processImage:image forceReprocessing:YES];
    }
    
    double heading1 = [self getCompassAngle:images[0]];
    double heading2 = [self getCompassAngle:images[1]];
    double heading3 = [self getCompassAngle:images[2]];
    
    
    // heading1 should point to location 2
    // heading2 should point to location 3
    // heading3 should be the same as heading2
    
    XCTAssert(heading1-44.091251 < 0.01);
    XCTAssert(heading2-223.943664 < 0.01);
    XCTAssertEqual(heading2, heading3);
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.currencyCode = @"SEK";
    
    [MAPFileManager deleteSequence:sequence];
}
    
- (double)getCompassAngle:(MAPImage*)image
{
    NSNumber* heading = @0;
    
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
                NSDictionary* MAPCompassHeading = json[kMAPCompassHeading];
                NSNumber* MAPTrueHeading = MAPCompassHeading[kMAPTrueHeading];
                
                heading = MAPTrueHeading;
            }
        }
        
        CFRelease(imageSource);
    }
    
    return heading.doubleValue;
}

@end
