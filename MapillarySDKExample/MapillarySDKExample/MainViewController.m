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
    
    if (self.sequence)
    {
        NSArray* images = [self.sequence listImages];
        self.photosLabel.text = [NSString stringWithFormat:@"%lu photos", (unsigned long)images.count];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - User

- (IBAction)signOutAction:(id)sender
{
    [MAPLoginManager signOut];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Sequence

- (IBAction)startNewSequenceAction:(id)sender
{
    MAPDevice* device = [[MAPDevice alloc] init];
    device.name = @"iPhone";
    device.make = @"Apple";
    device.model = @"iPhone";
    self.sequence = [[MAPSequence alloc] initWithDevice:device andProject:nil];
    
    self.startSequenceButton.enabled = NO;
    self.addPhotoButton.enabled = YES;
    self.deleteSequenceButton.enabled = YES;
}

- (IBAction)addPhotoAction:(id)sender
{
    /*UIImage* cameraImage = [UIImage imageNamed:@"mapillary_logo_big.jpg"];
    
    NSData* data = UIImageJPEGRepresentation(cameraImage, 1);
    MAPLocation* location = [[MAPLocation alloc] init];
    location.location = self.lastLocation;
    
    [self.sequence addImageWithData:data date:nil location:location];
    
    self.photosLabel.text = [NSString stringWithFormat:@"%d photos", self.photos];
    
    self.deleteSequenceButton.enabled = YES;*/
    
    CameraViewController* vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraViewController"];
    vc.sequence = self.sequence;
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

- (IBAction)deleteSequenceAction:(id)sender
{
    [MAPFileManager deleteSequence:self.sequence];
    
    self.photosLabel.text = @"0 photos";
    self.startSequenceButton.enabled = YES;
    self.addPhotoButton.enabled = NO;
    self.deleteSequenceButton.enabled = NO;
}

#pragma mark - Upload

- (IBAction)startUploadAction:(id)sender
{
    
}

- (IBAction)stopUploadAction:(id)sender
{
    
}

@end
