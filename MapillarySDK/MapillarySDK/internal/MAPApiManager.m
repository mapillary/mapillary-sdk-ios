//
//  MAPApiManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-07.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPApiManager.h"
#import "MAPDefines.h"
#import "AFNetworking.h"
#import <SAMKeychain/SAMKeychain.h>
#import "MAPInternalUtils.h"
#import "MAPDataManager.h"
#import "MAPUploadManager.h"
#import "MAPLoginManager.h"

@implementation MAPApiManager

+ (void)getCurrentUser:(void(^)(MAPUser* user))done
{
    NSString* url = @"v3/me";
    
    [self simpleGET:url responseObject:^(id responseObject, NSError* error) {
        
        MAPUser* user = nil;
        
        if (responseObject)
        {
            NSString* username = responseObject[@"username"];
            NSString* key = responseObject[@"key"];
            NSString* email = responseObject[@"email"];
            
            if (username && key)
            {
                user = [[MAPUser alloc] initWithUserName:username andUserKey:key andUserEmail:email andAccessToken:nil];
            }
        }
        
        if (done)
        {
            done(user);
        }
    }];
}

+ (void)logoutCurrentUser
{
    NSString* url = @"/v3/me/logout";
    NSDictionary* json = @{@"client_id" : [[NSBundle mainBundle] objectForInfoDictionaryKey:MAPILLARY_CLIENT_ID]};
    
    [self simplePOST:url json:json responseObject:^(id responseObject, NSError* error) {
        
        if (responseObject)
        {
            
        }
                
    }];
}

+ (void)startUploadSession:(void(^)(NSURL* url, NSDictionary* fields, NSString* sessionKey, NSString* keyPrefix))done
{
    NSString* url = @"v3/me/uploads/";
    NSDictionary* json = @{@"type" : @"images/sequence"};
    
    [self simplePOST:url json:json responseObject:^(id responseObject, NSError* error) {
        
        NSURL* url = nil;
        NSDictionary* fields = nil;
        NSString* sessionKey = nil;
        NSString* keyPrefix = nil;
        
        if (responseObject)
        {
            NSDictionary* dict = (NSDictionary*)responseObject;
            NSString* urlPath = dict[@"url"];
            NSString* status = dict[@"status"];
            
            if (urlPath && [status isEqualToString:@"open"])
            {
                url = [NSURL URLWithString:urlPath];
                fields = dict[@"fields"];
                sessionKey = dict[@"key"];
                keyPrefix = dict[@"key_prefix"];
            }
        }
        
        if (done)
        {
            done(url, fields, sessionKey, keyPrefix);
        }
        
    }];
}

+ (void)endUploadSession:(NSString*)sessionKey done:(void(^)(BOOL success))done
{
    MAPUploadSession* uploadSession = [[MAPDataManager sharedManager] getUploadSessionForSessionKey:sessionKey];
    
    if (uploadSession.closing)
    {
        if (done)
        {
            done(NO);
            return;
        }
    }
    
    uploadSession.closing = YES;
    [[MAPDataManager sharedManager] saveChanges];    
    
    NSString* url = [NSString stringWithFormat:@"v3/me/uploads/%@/closed", sessionKey];
    
    if ([MAPUploadManager sharedManager].testUpload)
    {
        url = [NSString stringWithFormat:@"v3/me/uploads/%@/closed?_dry_run", sessionKey];
    }
    
    [self simplePUT:url responseObject:^(id responseObject, NSError* error) {
                
        uploadSession.done = YES;
        [[MAPDataManager sharedManager] saveChanges];
        
        if (error == nil)
        {
            [[MAPDataManager sharedManager] removeUploadSession:uploadSession.uploadSessionKey];
            
            NSLog(@"CLOSED SESSION %@", sessionKey);
        }
        else
        {
            NSLog(@"FAILED TO CLOSE SESSION %@", sessionKey);
        }
        
        if (done)
        {
            done(error == nil);
        }
        
    }];
}

+ (void)getUploadSessions:(void(^)(NSArray* uploadSessionKeys))done
{
    NSString* url = @"v3/me/uploads/";
    NSMutableArray* uploadSessionKeys = [NSMutableArray array];
    
    [self simpleGET:url responseObject:^(id responseObject, NSError* error) {
        
        if (responseObject)
        {
            NSArray* sessions = (NSArray*)responseObject;
            
            for (NSDictionary* dict in sessions)
            {
                NSString* key = dict[@"key"];
                [uploadSessionKeys addObject:key];
            }
        }
        
        if (done)
        {
            done(uploadSessionKeys);
        }
        
    }];
}

#pragma mark - Util

+ (NSString*)fullUrlForUrlString:(NSString*)url
{
    NSString* clientId = [[NSBundle mainBundle] objectForInfoDictionaryKey:MAPILLARY_CLIENT_ID];
    NSString* baseUrl = kMAPAPIEndpoint; // @" https://28ca7d4c.ngrok.io";
    
    if ([MAPInternalUtils usingStaging])
    {
        baseUrl = kMAPAPIEndpointStaging;
        clientId = kMAPClientIdStaging;
    }
    
    clientId = [clientId stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
    
    NSMutableString* fullPath = [NSMutableString stringWithFormat:@"%@/%@", baseUrl, url];
    
    if ([fullPath containsString:@"?"])
    {
        [fullPath appendString:[NSString stringWithFormat:@"&client_id=%@", clientId]];
    }
    else
    {
        [fullPath appendString:[NSString stringWithFormat:@"?client_id=%@", clientId]];
    }
    
    return fullPath;
}

+ (AFHTTPSessionManager*)httpSessionManager
{
    NSString* accessToken = [SAMKeychain passwordForService:MAPILLARY_KEYCHAIN_SERVICE account:MAPILLARY_KEYCHAIN_ACCOUNT];
    NSString* header = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
    
    AFHTTPRequestSerializer* requestSerializer = [[AFHTTPRequestSerializer alloc] init];
    [requestSerializer setValue:header forHTTPHeaderField:@"Authorization"];
    manager.requestSerializer = requestSerializer;
    
    return manager;
}

+ (void)simpleGET:(NSString*)url responseObject:(void (^) (id responseObject, NSError* error))result
{
    NSString* path = [self fullUrlForUrlString:url];
    
    AFHTTPSessionManager* manager = [self httpSessionManager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
              
        /*if (response && response.statusCode == 401)
        {
            [self handle401:path];
        }*/
        
        if (response.statusCode != 200)
        {
            NSLog(@"Request failed: %ld", (long)response.statusCode);
        }
        
        if (result)
        {
            result(responseObject, nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"Request failed: %@", error);
        
        if (result)
        {
            result(nil, error);
        }
        
    }];
}

+ (void)simplePATCH:(NSString*)url json:(NSDictionary*)json responseObject:(void (^) (id responseObject, NSError* error))result
{
    NSString* path = [self fullUrlForUrlString:url];
    
    AFHTTPSessionManager* manager = [self httpSessionManager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest* request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"PATCH" URLString:path parameters:nil error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
   NSURLSessionDataTask* task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
       
       NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
       
       /*if (httpResponse && httpResponse.statusCode == 401)
       {
           [self handle401:path];
       }*/
       
       if (httpResponse.statusCode != 200)
       {
           NSLog(@"Request failed: %ld", (long)httpResponse.statusCode);
       }
       
       if (error)
       {
           NSLog(@"Request failed: %@", error);
       }
       
       if (result)
       {
           result(responseObject, error);
       }
        
    }];
    
    [task resume];
}

+ (void)simplePOST:(NSString*)url json:(NSDictionary*)json responseObject:(void (^) (id responseObject, NSError* error))result
{
    NSString* path = [self fullUrlForUrlString:url];
    
    AFHTTPSessionManager* manager = [self httpSessionManager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableURLRequest* request = [manager.requestSerializer requestWithMethod:@"POST" URLString:path parameters:nil error:nil];
    
    if (json)
    {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
        NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSURLSessionDataTask* task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
              
        /*if (httpResponse && httpResponse.statusCode == 401)
        {
            [self handle401:path];
        }*/
        
        if (httpResponse.statusCode != 200)
        {
            NSLog(@"Request failed: %ld", (long)httpResponse.statusCode);
        }
    
        if (error)
        {
            NSLog(@"Request failed: %@", error);
        }
        
        if (result)
        {
            result(responseObject, error);
        }
    }];
    
    
    [task resume];
}

+ (void)simplePUT:(NSString*)url responseObject:(void (^) (id responseObject, NSError* error))result
{
    NSString* path = [self fullUrlForUrlString:url];
    
    AFHTTPSessionManager* manager = [self httpSessionManager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager PUT:path parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
        
        /*if (response.statusCode == 401)
        {
            [self handle401:path];
        }*/
        
        if (response.statusCode != 200)
        {
            NSLog(@"Request failed: %ld", (long)response.statusCode);
        }
        
        if (result)
        {
            result(responseObject, nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"Request failed: %@", error);
        
        if (result)
        {
            result(nil, error);
        }
        
    }];
}

+ (void)handle401:(NSString*)reason
{
    [MAPLoginManager signOut:reason];
}

@end
