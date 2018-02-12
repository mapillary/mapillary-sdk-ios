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

@property XCTestExpectation* expectationUploadStarted;
@property XCTestExpectation* expectationImageUploaded;
@property XCTestExpectation* expectationSequenceFinished;
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
    self.expectationUploadStarted = [self expectationWithDescription:@"Adding non Mapillary GPX file"];
    self.expectationImageUploaded = [self expectationWithDescription:@"Adding non Mapillary GPX file"];
    self.expectationSequenceFinished = [self expectationWithDescription:@"Adding non Mapillary GPX file"];
    self.expectationUploadFinished = [self expectationWithDescription:@"Adding non Mapillary GPX file"];
    
    MAPSequence* s = [self createSequence:5];
    [[MAPUploadManager sharedManager] uploadSequences:@[s] allowsCellularAccess:NO];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
    }];
    
}

#pragma mark - MAPUploadManagerDelegate

- (void)uploadStarted:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{
    [self.expectationUploadStarted fulfill];
}

- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus error:(NSError*)error
{
    if (error == nil)
    {
        [self.expectationImageUploaded fulfill];
    }
    else
    {
        XCTFail(@"Expectation failed with error: %@", error);
    }
}

- (void)sequenceFinished:(MAPUploadManager*)uploadManager sequence:(MAPSequence*)sequence uploadStatus:(MAPUploadStatus*)uploadStatus
{
    [self.expectationSequenceFinished fulfill];
}

- (void)uploadFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{
    [self.expectationUploadFinished fulfill];
}

- (void)uploadStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{
    
}

#pragma mark - Utils

- (NSData*)createImageData
{
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 100, 100));
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    return UIImageJPEGRepresentation(image, 1);
}

- (MAPSequence*)createSequence:(int)countImages
{
    MAPDevice* device = [MAPDevice currentDevice];
    MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:device];
    
    NSData* imageData = [self createImageData];
    
    for (int i = 0; i < countImages; i++)
    {
        [sequence addImageWithData:imageData date:nil location:nil];
    }
    
    return sequence;
}

- (void)deleteAllSequences
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [MAPFileManager listSequences:^(NSArray *sequences) {
        
        for (MAPSequence* s in sequences)
        {
            [MAPFileManager deleteSequence:s];
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    dispatch_semaphore_wait(semaphore, 60);
}

@end
