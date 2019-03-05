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

@interface MAPLoginViewController ()

@end

@implementation MAPLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies)
    {
        [cookieStorage deleteCookie:each];
    }

    self.webView.delegate = self;
    self.webView.hidden = YES;

    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.urlString]];
    [self.webView loadRequest:request];
}

#pragma mark - Button actions

- (IBAction)cancelAction:(id)sender
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"localStorage.clear()"];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        if ([self.delegate respondsToSelector:@selector(didCancel:)])
        {
            [self.delegate didCancel:self];
        }
        
    }];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.spinner stopAnimating];
    self.webView.hidden = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    
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
    
    if (access_token != nil && access_token.length > 0)
    {
        [self.webView stringByEvaluatingJavaScriptFromString:@"localStorage.clear()"];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            if ([self.delegate respondsToSelector:@selector(didLogin:accessToken:)])
            {
                [self.delegate didLogin:self accessToken:access_token];
            }
            
        }];
    }
    
    return YES;
}

@end
