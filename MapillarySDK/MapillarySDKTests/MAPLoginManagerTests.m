//
//  MAPLoginManagerTests.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"
#import <OCMockito/OCMockito.h>

@interface MAPLoginManagerTests : XCTestCase

@end

@implementation MAPLoginManagerTests

- (void)setUp
{
    [super setUp];
    
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testSignOut
{
    [MAPLoginManager signOut];
    
    // Not logged in, no user should be signed in
    
    MAPUser* currentUser = [MAPLoginManager currentUser];
    XCTAssertNil(currentUser);
}



@end
