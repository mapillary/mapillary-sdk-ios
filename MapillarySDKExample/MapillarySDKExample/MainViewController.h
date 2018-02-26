//
//  MainViewController.h
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-12-18.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController


@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UIButton *startSequenceButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;

- (IBAction)signOutAction:(id)sender;

@end
