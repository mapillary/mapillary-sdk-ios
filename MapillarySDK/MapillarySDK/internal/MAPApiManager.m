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

@implementation MAPApiManager

+ (void)getCurrentUser:(void(^)(MAPUser* user))done
{
    NSString* url = @"v3/me";
    
    [self simpleGET:url responseObject:^(id responseObject) {
        
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

+ (void)startUploadSession:(void(^)(NSURL* url, NSDictionary* fields, NSString* sessionKey, NSString* keyPrefix))done
{
    NSString* url = @"v3/me/uploads/";
    NSDictionary* json = @{@"type" : @"images/sequence"};
    
    [self simplePOST:url json:json responseObject:^(id responseObject) {
        
        NSURL* url = nil;
        NSDictionary* fields = nil;
        NSString* sessionKey = nil;
        NSString* keyPrefix = nil;
        
        if (responseObject)
        {
            NSDictionary* dict = (NSDictionary*)responseObject;
            NSString* urlPath = dict[@"url"];
            NSString* status = dict[@"status"];
            
            // urlPath = @"http://b2f6c0708c31.ngrok.io";
            // urlPath = @"https://postman-echo.com/post";
            
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

+ (void)endUploadSession:(NSString*)sessionKey
{
    NSString* url = [NSString stringWithFormat:@"v3/me/uploads%@/closed", sessionKey];
    
    [self simplePUT:url responseObject:^(id responseObject) {
        
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

+ (void)simpleGET:(NSString*)url responseObject:(void (^) (id responseObject))result
{
    NSString* path = [self fullUrlForUrlString:url];
    
    AFHTTPSessionManager* manager = [self httpSessionManager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
        
        if (response.statusCode != 200)
        {
            NSLog(@"Request failed: %ld", (long)response.statusCode);
        }
        
        if (result)
        {
            result(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"Request failed: %@", error);
        
        if (result)
        {
            result(nil);
        }
        
    }];
}

+ (void)simplePATCH:(NSString*)url json:(NSDictionary*)json responseObject:(void (^) (id responseObject))result
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
        
        if (error)
        {
            NSLog(@"Request failed: %@", error);
        }
        
        if (result)
        {
            result(responseObject);
        }
        
    }];
    
    [task resume];
}

+ (void)simplePOST:(NSString*)url json:(NSDictionary*)json responseObject:(void (^) (id responseObject))result
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
    
        if (error)
        {
            NSLog(@"Request failed: %@", error);
        }
        
        if (result)
        {
            result(responseObject);
        }
    }];
    
    
    [task resume];
}

+ (void)simplePUT:(NSString*)url responseObject:(void (^) (id responseObject))result
{
    NSString* path = [self fullUrlForUrlString:url];
    
    AFHTTPSessionManager* manager = [self httpSessionManager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager PUT:path parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)task.response;
        
        if (response.statusCode != 200)
        {
            NSLog(@"Request failed: %ld", (long)response.statusCode);
        }
        
        if (result)
        {
            result(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"Request failed: %@", error);
        
        if (result)
        {
            result(nil);
        }
        
    }];
}

@end
