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
    
    [MAPFileManager getSequencesAsync:NO done:^(NSArray *sequences) {
        
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
    MAPUploadManagerStatus* status = [self.uploadManager getStatus];
    
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
    MAPUploadManagerStatus* status = [self.uploadManager getStatus];

    if (status.uploading)
    {
        float processProgress = (float)status.imagesProcessed/status.imageCount;
        float uploadProgress = (float)status.imagesUploaded/status.imageCount;
        
        [self.imagesProcessedProgressView setProgress:processProgress animated:NO];
        [self.imagesUploadedProgressView setProgress:uploadProgress animated:NO];
        
        self.statusLabel.text = [NSString stringWithFormat:@"Uploading...\n(%.1f kb/s)", status.uploadSpeedBytesPerSecond/1024.0f];
    }
    else
    {
        self.imagesProcessedProgressView.progress = 0;
        self.imagesUploadedProgressView.progress = 0;
    }
    
    self.imagesProcessedLabel.text = [NSString stringWithFormat:@"Images processed (%lu/%lu)", (unsigned long)status.imagesProcessed, (unsigned long)status.imageCount];
    self.imagesUploadedLabel.text = [NSString stringWithFormat:@"Images uploaded (%lu/%lu)", (unsigned long)status.imagesUploaded, (unsigned long)status.imageCount];
}

#pragma mark - Button actions

- (IBAction)buttonAction:(id)sender
{
    MAPUploadManagerStatus* status = [self.uploadManager getStatus];
    
    if (!status.uploading)
    {
        [self.uploadManager processAndUploadSequences:self.sequences];
    }
    else
    {
        [self.uploadManager stopUpload];
    }
    
    [self updateUI];
}

#pragma mark - MAPUploadManagerDelegate

- (void)imageProcessed:(MAPUploadManager *)uploadManager image:(MAPImage *)image status:(MAPUploadManagerStatus*)status
{
    [self updateProgress];
}

- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status
{
    [self updateProgress];
}

- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status error:(NSError*)error
{
    [self updateProgress];
}

- (void)uploadFinished:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
    self.statusLabel.text = @"Upload finished";
    [self.button setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)uploadStopped:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
    self.statusLabel.text = @"Upload stopped";
    [self.button setTitle:@"Start" forState:UIControlStateNormal];
}

@end
