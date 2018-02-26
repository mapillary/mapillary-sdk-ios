//
//  MainViewController.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-12-18.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import "MainViewController.h"
#import <MapillarySDK/MapillarySDK.h>
#import "CameraViewController.h"
#import <SDVersion/SDVersion.h>

@interface MainViewController ()

@property MAPSequence* sequence;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sequence = nil;    
    
    MAPUser* me = [MAPLoginManager currentUser];
    self.userLabel.text = [NSString stringWithFormat:@"Logged in with: %@", me.userName];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Button actions

- (IBAction)signOutAction:(id)sender
{
    [MAPLoginManager signOut];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
