//
//  MAPLoginViewController.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-03-02.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class MAPLoginViewController;

@protocol MAPLoginViewControllerDelegate <NSObject>
- (void)didLogin:(MAPLoginViewController*)loginViewController accessToken:(NSString*)accessToken;
- (void)didCancel:(MAPLoginViewController*)loginViewController;
@end

@interface MAPLoginViewController : UIViewController  <WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (nonatomic, weak) id<MAPLoginViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic) NSString* urlString;

- (IBAction)cancelAction:(id)sender;

@end
