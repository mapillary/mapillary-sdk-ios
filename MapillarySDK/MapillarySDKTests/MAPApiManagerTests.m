//
//  MAPApiManagerTests.m
//  MapillarySDKTests
//
//  Created by Anders Mårtensson on 2017-10-25.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"
#import "MAPApiManager.h"

@interface MAPApiManagerTests : XCTestCase

@end

@implementation MAPApiManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCurrentUserNotLoggedIn
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Current user when not logged in should be nil"];
    
    [MAPApiManager getCurrentUser:^(MAPUser *user) {
        
        XCTAssertNil(user);
        [expectation fulfill];+
        
    }];
    
    // Wait for test to finish
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        
        if (error)
        {
            XCTFail(@"Expectation failed with error: %@", error);
        }
        
    }];
}

@end
