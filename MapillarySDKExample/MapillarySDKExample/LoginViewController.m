//
//  LoginViewController.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-10-30.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import "LoginViewController.h"
#import <MapillarySDK/MapillarySDK.h>

@interface LoginViewController ()

@end

@implementation LoginViewController


- (void)viewDidAppear:(BOOL)animated
{
    if ([MAPLoginManager isSignedIn])
    {
        [self nextScreen];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)buttonAction:(id)sender
{
    if (![MAPLoginManager isSignedIn])
    {
        self.button.enabled = NO;
        
        [MAPLoginManager signInFromViewController:self result:^(BOOL success) {
            
            if (success)
            {
                [self nextScreen];
            }
            else
            {
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Not logged in" message:@"Failed to sign in" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
            self.button.enabled = YES;
            
        } cancelled:^{
            
            self.button.enabled = YES;
            
        }];
    }
}

- (void)nextScreen
{
    UIViewController* vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
