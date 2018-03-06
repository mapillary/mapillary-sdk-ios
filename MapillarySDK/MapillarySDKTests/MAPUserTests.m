//
//  MAPUserTests.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-23.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MapillarySDK.h"

@interface MAPUserTests : XCTestCase

@end

@implementation MAPUserTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testUserNameAndUserKey
{
    NSString* userName = @"Mappy";
    NSString* userKey = [[NSUUID UUID] UUIDString];
    
    MAPUser* user = [[MAPUser alloc] initWithUserName:userName andUserKey:userKey];
    
    XCTAssertTrue([userName isEqualToString:[user userName]]);
    XCTAssertTrue([userKey isEqualToString:[user userKey]]);
}

- (void)testUserNameAndUserKeyAndAccessToken
{
    NSString* userName = @"Mappy";
    NSString* userKey = [[NSUUID UUID] UUIDString];
    NSString* accessToken = [[NSUUID UUID] UUIDString];
    
    MAPUser* user = [[MAPUser alloc] initWithUserName:userName andUserKey:userKey andAccessToken:accessToken];
    
    XCTAssertTrue([userName isEqualToString:[user userName]]);
    XCTAssertTrue([userKey isEqualToString:[user userKey]]);
    XCTAssertTrue([accessToken isEqualToString:[user accessToken]]);
}

- (void)testNil
{
    MAPUser* user = [[MAPUser alloc] initWithUserName:nil andUserKey:nil andAccessToken:nil];
    
    XCTAssertNotNil(user);
}

@end
