//
//  MainViewController.h
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-12-18.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

#pragma mark - User
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
- (IBAction)signOutAction:(id)sender;

#pragma mark - Sequence
@property (weak, nonatomic) IBOutlet UIButton *startSequenceButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteSequenceButton;
@property (weak, nonatomic) IBOutlet UILabel *photosLabel;
- (IBAction)startNewSequenceAction:(id)sender;
- (IBAction)addPhotoAction:(id)sender;
- (IBAction)deleteSequenceAction:(id)sender;

#pragma mark - Upload
- (IBAction)startUploadAction:(id)sender;
- (IBAction)stopUploadAction:(id)sender;

@end
