//
//  CameraViewController.h
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-12-18.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapillarySDK/MapillarySDK.h>
#import <AVKit/AVKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CameraViewController : UIViewController <AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;

- (IBAction)captureAction:(id)sender;
- (IBAction)exitAction:(id)sender;

@end
