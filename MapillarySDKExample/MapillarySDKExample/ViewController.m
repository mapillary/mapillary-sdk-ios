//
//  ViewController.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-10-30.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import "ViewController.h"
#import <MapillarySDK/MapillarySDK.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self update];
}

- (void)update
{
    if ([MAPLoginManager isSignedIn])
    {
        self.label.text = [NSString stringWithFormat:@"Signed in with %@.", [MAPLoginManager currentUser].userName];
        [self.button setTitle:@"Sign out" forState:UIControlStateNormal];
    }
    else
    {
        self.label.text = @"No user is currently signed in.";
        [self.button setTitle:@"Sign in" forState:UIControlStateNormal];
    }
}

- (IBAction)buttonAction:(id)sender
{
    if (![MAPLoginManager isSignedIn])
    {
        self.label.text = @"Signing in...";
        self.button.enabled = NO;
        self.button.alpha = 0.5;
        
        [MAPLoginManager signIn:^(BOOL success) {
            
            UIAlertController* alert = nil;
            UIAlertAction* action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
            
            if (success)
            {
                alert = [UIAlertController alertControllerWithTitle:@"Logged in" message:@"Sign in was successful" preferredStyle:UIAlertControllerStyleAlert];
            }
            else
            {
                alert = [UIAlertController alertControllerWithTitle:@"Not logged in" message:@"Failed to sign in" preferredStyle:UIAlertControllerStyleAlert];
            }
            
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
            
            [self update];
            
            self.button.enabled = YES;
            self.button.alpha = 1.0;

        }];
    }
    else
    {
        [MAPLoginManager signOut];
        [self update];
    }
}

@end
