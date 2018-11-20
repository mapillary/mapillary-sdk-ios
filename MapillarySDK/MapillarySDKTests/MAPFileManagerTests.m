//
//  MAPFileManagerTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2018-03-06.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"

@interface MAPFileManagerTests : XCTestCase

@end

@implementation MAPFileManagerTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{    
    [super tearDown];
}

- (void)testListAndDeleteSeqiuences
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Failed to list and delete sequences"];
    
    MAPDevice* device = [MAPDevice thisDevice];
    
    [MAPFileManager getSequencesAsync:YES done:^(NSArray *sequences) {
        
        for (MAPSequence* s in sequences)
        {
            [MAPFileManager deleteSequence:s];
        }
        
        MAPSequence* s = [[MAPSequence alloc] initWithDevice:device];
        XCTAssertNotNil(s);
        
        [MAPFileManager getSequencesAsync:YES done:^(NSArray *sequences) {
            
            XCTAssertEqual(sequences.count, 1);
            
            MAPSequence* s = [[MAPSequence alloc] initWithDevice:device];
            XCTAssertNotNil(s);
    
            [MAPFileManager getSequencesAsync:YES done:^(NSArray *sequences) {
                
                XCTAssertEqual(sequences.count, 2);
                
                [MAPFileManager deleteSequence:sequences[0]];
                
                [MAPFileManager getSequencesAsync:YES done:^(NSArray *sequences) {
                    
                    XCTAssertEqual(sequences.count, 1);
                    
                    [MAPFileManager deleteSequence:sequences[0]];
                    
                    [MAPFileManager getSequencesAsync:YES done:^(NSArray *sequences) {
                        
                        XCTAssertEqual(sequences.count, 0);

                        [expectation fulfill];
                        
                    }];
                }];
            }];
        }];
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
        
    }];
}

@end
