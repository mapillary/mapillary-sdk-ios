//
//  UploadViewController.h
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2018-02-20.
//  Copyright © 2018 com.mapillary.sdk.example. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapillarySDK/MapillarySDK.h>

@interface UploadViewController : UIViewController <MAPUploadManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *imagesProcessedLabel;
@property (weak, nonatomic) IBOutlet UILabel *imagesUploadedLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *imagesProcessedProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *imagesUploadedProgressView;
@property (weak, nonatomic) IBOutlet UIButton *button;

- (IBAction)buttonAction:(id)sender;

@end
