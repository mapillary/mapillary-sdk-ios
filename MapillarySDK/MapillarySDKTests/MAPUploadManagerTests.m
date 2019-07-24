//
//  MAPUploadManagerTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2018-01-26.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <OCMock/OCMock.h>
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
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testStopUploadResetsStatus
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    [uploadManager stopUpload];
    XCTAssertFalse(uploadManager.getStatus.processing);
    XCTAssertFalse(uploadManager.getStatus.uploading);
}

- (void)testStopUploadUnlockSequence
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    
    id sequence = OCMClassMock([MAPSequence class]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    
    [uploadManager uploadSequences:sequences];
    sleep(2);
    [uploadManager stopUpload];
    sleep(2);
    
    XCTAssertFalse(uploadManager.getStatus.processing);
    OCMVerify([sequence unlock]);
}

- (void)testStopProcessingUnlockSequence
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    
    id sequence = OCMClassMock([MAPSequence class]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    id partialUploadManagerMock = OCMPartialMock(uploadManager);
    OCMExpect([partialUploadManagerMock startUpload:NO]);
    
    [uploadManager uploadSequences:sequences];
    sleep(2);
    [uploadManager stopProcessing];
    sleep(2);
    
    XCTAssertFalse(uploadManager.getStatus.processing);
    OCMVerify([sequence unlock]);
    [partialUploadManagerMock stopMocking];
}

- (void)testProcessSequenceLockTheSequence
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    uploadManager.getStatus.processing = NO;
    uploadManager.getStatus.uploading = NO;
    id sequence = OCMClassMock([MAPSequence class]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    [uploadManager processSequences:sequences forceReprocessing:YES];
    sleep(2);
    OCMVerify([sequence lock]);
}

- (void)testProcessSequencesDoesNotUpdateCountersIfProcessing
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    uploadManager.getStatus.processing = YES;
    uploadManager.getStatus.imageCount = 10;
    uploadManager.getStatus.imagesFailed = 9;
    uploadManager.getStatus.imagesUploaded = 8;
    uploadManager.getStatus.imagesProcessed = 7;
    uploadManager.getStatus.uploadSpeedBytesPerSecond = 6;
    id sequence = OCMClassMock([MAPSequence class]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    [uploadManager processSequences:sequences forceReprocessing:YES];
    XCTAssertTrue(uploadManager.getStatus.processing);
    XCTAssertEqual(uploadManager.getStatus.imageCount, 10);
    XCTAssertEqual(uploadManager.getStatus.imagesFailed, 9);
    XCTAssertEqual(uploadManager.getStatus.imagesUploaded, 8);
    XCTAssertEqual(uploadManager.getStatus.imagesProcessed, 7);
    XCTAssertEqual(uploadManager.getStatus.uploadSpeedBytesPerSecond, 6);
}

- (void)testProcessSequencesCountersAreResetedIfNotProcessing
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    uploadManager.getStatus.processing = NO;
    uploadManager.getStatus.uploading = NO;
    uploadManager.getStatus.imageCount = 10;
    uploadManager.getStatus.imagesFailed = 9;
    uploadManager.getStatus.imagesUploaded = 8;
    uploadManager.getStatus.imagesProcessed = 7;
    uploadManager.getStatus.uploadSpeedBytesPerSecond = 6;
    id sequence = OCMClassMock([MAPSequence class]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    [uploadManager processSequences:sequences forceReprocessing:YES];
    XCTAssertTrue(uploadManager.getStatus.processing);
    XCTAssertEqual(uploadManager.getStatus.imageCount, 0);
    XCTAssertEqual(uploadManager.getStatus.imagesFailed, 0);
    XCTAssertEqual(uploadManager.getStatus.imagesUploaded, 0);
    XCTAssertEqual(uploadManager.getStatus.imagesProcessed, 0);
    XCTAssertEqual(uploadManager.getStatus.uploadSpeedBytesPerSecond, 0);
}

- (void)testProcessSequencesIncreasesTheImagesCount
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    uploadManager.getStatus.processing = NO;
    uploadManager.getStatus.uploading = NO;
    uploadManager.getStatus.imageCount = 10;
    
    id sequence = OCMClassMock([MAPSequence class]);
    id image = OCMClassMock([MAPImage class]);
    id partialUploadManagerMock = OCMPartialMock(uploadManager);
    
    OCMExpect([partialUploadManagerMock startProcessing:YES]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    NSArray *images = [NSArray arrayWithObjects:image, nil];
    OCMStub([sequence getImages]).andReturn(images);
    
    [uploadManager processSequences:sequences forceReprocessing:YES];
    sleep(1);
    XCTAssertEqual(uploadManager.getStatus.imageCount, 1);
    [partialUploadManagerMock stopMocking];
}

- (void)testProcessAndUploadSequencesLockTheSequences
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    
    id sequence = OCMClassMock([MAPSequence class]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    
    [uploadManager processAndUploadSequences:sequences forceReprocessing:YES];
    OCMVerify([sequence lock]);
}

- (void)testProcessAndUploadSequencesStartsTheUpload
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];
    
    id sequence = OCMClassMock([MAPSequence class]);
    id image = OCMClassMock([MAPImage class]);
    id partialUploadManagerMock = OCMPartialMock(uploadManager);
    
    OCMExpect([partialUploadManagerMock startUpload:YES]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    NSArray *images = [NSArray arrayWithObjects:image, nil];
    OCMStub([sequence getImages]).andReturn(images);
    
    [uploadManager processAndUploadSequences:sequences forceReprocessing:YES];
    sleep(2);
    OCMVerify([partialUploadManagerMock startUpload:YES]);
    [partialUploadManagerMock stopMocking];
}


- (void)testProcessSequencesCallsStartProcessing
{
    MAPUploadManager *uploadManager = [MAPUploadManager new];

    id sequence = OCMClassMock([MAPSequence class]);
    id image = OCMClassMock([MAPImage class]);
    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
    NSArray *images = [NSArray arrayWithObjects:image, nil];
    OCMStub([sequence getImages]).andReturn(images);
    
    id partialUploadManagerMock = OCMPartialMock(uploadManager);
    OCMExpect([partialUploadManagerMock startProcessing:YES]);
    
    [uploadManager processSequences:sequences forceReprocessing:YES];
    sleep(2);
    XCTAssertTrue(uploadManager.getStatus.processing);
    OCMVerify([partialUploadManagerMock startProcessing:YES]);
    [partialUploadManagerMock stopMocking];
}

//- (void)testProcessSequencesCreatesBookeepForAllImages
//{
//    MAPUploadManager *uploadManager = [MAPUploadManager new];
//
//    id sequence = OCMClassMock([MAPSequence class]);
//    id image = OCMClassMock([MAPImage class]);
//    id partialUploadManagerMock = OCMPartialMock(uploadManager);
//
//    OCMExpect([partialUploadManagerMock createBookkeepingForImage:image]);
//    NSArray *sequences = [NSArray arrayWithObjects:sequence, nil];
//    NSArray *images = [NSArray arrayWithObjects:image, nil];
//    OCMStub([sequence getImages]).andReturn(images);
//
//    [uploadManager processSequences:sequences forceReprocessing:YES];
//    sleep(2);
//    XCTAssertTrue(uploadManager.getStatus.processing);
//    OCMVerify([partialUploadManagerMock createBookkeepingForImage:image]);
//    [partialUploadManagerMock stopMocking];
//}



@end
