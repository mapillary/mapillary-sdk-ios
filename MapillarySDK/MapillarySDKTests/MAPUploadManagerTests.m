//
//  MAPUploadManagerTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2018-01-26.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"

@interface MAPUploadManagerTests : XCTestCase <MAPUploadManagerDelegate>

@property XCTestExpectation* expectationImageProcessed;
@property XCTestExpectation* expectationImageUploaded;
@property XCTestExpectation* expectationUploadFinished;

@end

@implementation MAPUploadManagerTests

- (void)setUp
{
    [super setUp];
    
    [self deleteAllSequences];
    [MAPUploadManager sharedManager].delegate = self;
}

- (void)tearDown
{
    [self deleteAllSequences];
    [MAPUploadManager sharedManager].delegate = nil;
    
    [super tearDown];
}

- (void)testSingleSequence
{
    self.expectationImageProcessed = [self expectationWithDescription:@"Processing image"];
    self.expectationImageUploaded = [self expectationWithDescription:@"Uploading image"];
    self.expectationUploadFinished = [self expectationWithDescription:@"Upload finished"];
    
    MAPSequence* s = [self createSequence:1];
    [[MAPUploadManager sharedManager] uploadSequences:@[s] allowsCellularAccess:NO deleteAfterUpload:YES];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    
}

#pragma mark - MAPUploadManagerDelegate

- (void)imageProcessed:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status
{
    [self.expectationImageProcessed fulfill];
}

- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status
{
    [self.expectationImageUploaded fulfill];
}

- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status error:(NSError*)error
{
    
}

- (void)uploadFinished:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
    [self.expectationUploadFinished fulfill];
}

- (void)uploadStopped:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
    
}

#pragma mark - Utils

- (NSData*)createImageData
{
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 100, 100));
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    return UIImageJPEGRepresentation(image, 1);
    
    /*NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test-image" ofType:@"jpg"];
    NSData* imageData = [NSData dataWithContentsOfFile:path];
    return imageData;*/
}

- (MAPSequence*)createSequence:(int)countImages
{
    MAPDevice* device = [MAPDevice currentDevice];
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:device];
    
    NSData* imageData = [self createImageData];
    
    for (int i = 0; i < countImages; i++)
    {
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = [[CLLocation alloc] initWithLatitude:55+i longitude:55+1];
        [sequence addImageWithData:imageData date:nil location:location];
    }
    
    return sequence;
}

- (void)deleteAllSequences
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [MAPFileManager getSequences:^(NSArray *sequences) {
        
        for (MAPSequence* s in sequences)
        {
            [MAPFileManager deleteSequence:s];
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    dispatch_semaphore_wait(semaphore, 60);
}

@end
