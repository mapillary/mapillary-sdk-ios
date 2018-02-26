//
//  UploadViewController.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2018-02-20.
//  Copyright © 2018 com.mapillary.sdk.example. All rights reserved.
//

#import "UploadViewController.h"

@interface UploadViewController ()

@property (nonatomic) MAPUploadManager* uploadManager;
@property (nonatomic) NSArray* sequences;

@end

@implementation UploadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.uploadManager = [MAPUploadManager sharedManager];
    self.uploadManager.delegate = self;
    self.uploadManager.testUpload = YES; // This will upload to our test server instead
    
    self.imagesProcessedProgressView.progress = 0;
    self.imagesUploadedProgressView.progress = 0;
    
    [self.button setEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    [MAPFileManager listSequences:^(NSArray *sequences) {
        
        self.sequences = sequences;
        
        if (self.sequences.count > 0)
        {
            [self.button setEnabled:YES];
        }
        
        [self updateUI];
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.uploadManager.delegate = nil;
}

- (void)updateUI
{
    MAPUploadStatus* status = [self.uploadManager getStatus];
    
    if (!status.uploading)
    {
        [self.button setTitle:@"Start" forState:UIControlStateNormal];
        self.statusLabel.text = [NSString stringWithFormat:@"%d sequences to upload", (int)self.sequences.count];
    }
    else
    {
        [self.button setTitle:@"Stop" forState:UIControlStateNormal];
        self.statusLabel.text = @"Uploading...";
    }
    
    [self updateProgress];
}

- (void)updateProgress
{
    MAPUploadStatus* status = [self.uploadManager getStatus];

    if (status.uploading)
    {
        float processProgress = (float)status.imagesProcessed/status.imagesToUpload;
        float uploadProgress = (float)status.imagesUploaded/status.imagesToUpload;
        
        [self.imagesProcessedProgressView setProgress:processProgress animated:YES];
        [self.imagesUploadedProgressView setProgress:uploadProgress animated:YES];
    }
    else
    {
        self.imagesProcessedProgressView.progress = 0;
        self.imagesUploadedProgressView.progress = 0;
    }
    
    self.imagesProcessedLabel.text = [NSString stringWithFormat:@"Images processed (%lu/%lu)", (unsigned long)status.imagesProcessed, (unsigned long)status.imagesToUpload];
    self.imagesUploadedLabel.text = [NSString stringWithFormat:@"Images uploaded (%lu/%lu)", (unsigned long)status.imagesUploaded, (unsigned long)status.imagesToUpload];
}

#pragma mark - Button actions

- (IBAction)buttonAction:(id)sender
{
    MAPUploadStatus* status = [self.uploadManager getStatus];
    
    if (!status.uploading)
    {
        [self.uploadManager uploadSequences:self.sequences allowsCellularAccess:NO deleteAfterUpload:NO];
    }
    else
    {
        [self.uploadManager stopUpload];
    }
    
    [self updateUI];
}

#pragma mark - MAPUploadManagerDelegate

- (void)imageProcessed:(MAPUploadManager *)uploadManager image:(MAPImage *)image uploadStatus:(MAPUploadStatus*)uploadStatus
{
    [self updateProgress];
}

- (void)uploadStarted:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{

}

- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus error:(NSError*)error
{
    [self updateProgress];
}

- (void)uploadFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{
    self.statusLabel.text = @"Upload finished";
    [self.button setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)uploadStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{
    self.statusLabel.text = @"Upload stopped";
    [self.button setTitle:@"Start" forState:UIControlStateNormal];
}

@end
