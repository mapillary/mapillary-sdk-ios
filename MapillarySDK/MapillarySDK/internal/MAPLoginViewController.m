//
//  MAPLoginViewController.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-03-02.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPLoginViewController.h"
#import "MAPApiManager.h"
#import "MAPDefines.h"
#import "MAPInternalUtils.h"

@interface MAPLoginViewController ()

@end

@implementation MAPLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self cleanUp];

    self.webView.navigationDelegate = self;
    self.webView.hidden = YES;
    
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.urlString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    [self.webView loadRequest:request];
}

- (void)cleanUp
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie* each in cookieStorage.cookies)
    {
        [cookieStorage deleteCookie:each];
    }
    
    if (self.webView)
    {
        [self.webView evaluateJavaScript:@"localStorage.clear()" completionHandler:nil];
    }
    
    [MAPInternalUtils deleteNetworkCache];
}

#pragma mark - Button actions

- (IBAction)cancelAction:(id)sender
{
    [self.webView evaluateJavaScript:@"localStorage.clear()" completionHandler:nil];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        if ([self.delegate respondsToSelector:@selector(didCancel:)])
        {
            [self.delegate didCancel:self];
        }
        
    }];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self.spinner stopAnimating];
    self.webView.hidden = NO;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL* url = navigationAction.request.URL;
    
    NSMutableDictionary* queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSArray* urlComponents = [url.absoluteString componentsSeparatedByString:@"&"];
    
    for (NSString* keyValuePair in urlComponents)
    {
        NSArray* pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString* key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString* value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        
        [queryStringDictionary setObject:value forKey:key];
    }
    
    NSString* access_token = queryStringDictionary[@"access_token"];
    
    BOOL exit = NO;
    
    if ([MAPInternalUtils usingStaging])
    {
        NSURL* redirectUrl = [NSURL URLWithString:kMAPRedirectURLStaging];
        if ([url.host isEqualToString:redirectUrl.host] && url.port == redirectUrl.port)
        {
            exit = YES;
        }
    }
    else
    {
        NSString* callbackUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:MAPILLARY_CLIENT_CALLBACK_URL];
        NSString* redirectUrl = [NSString stringWithFormat:@"/v2/oauth/%@", callbackUrl];
        if ([url.path isEqualToString:redirectUrl])
        {
            exit = YES;
        }
    }
    
    // User clicked "Allow" or "Deny"
    if (exit)
    {
        [self cleanUp];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            if ([self.delegate respondsToSelector:@selector(didLogin:accessToken:)])
            {
                [self.delegate didLogin:self accessToken:access_token];
            }
            
        }];
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
