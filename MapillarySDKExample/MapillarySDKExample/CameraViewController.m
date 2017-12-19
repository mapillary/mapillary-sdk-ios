//
//  CameraViewController.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-12-18.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()

@property AVCaptureSession* captureSession;
@property AVCapturePhotoOutput* stillCameraOutput;
@property CLLocationManager* locationManager;
@property CLLocation* lastLocation;
@property BOOL cameraBusy;

@end

@implementation CameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cameraBusy = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupLocationManager];
    [self setupCamera];
}

- (void)setupLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)setupCamera
{
    // Get the back facing wide-angle camera
    AVCaptureDevice* captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    // Configure camera
    if ([captureDevice lockForConfiguration:nil])
    {
        // Set focus to far
        if (captureDevice.autoFocusRangeRestrictionSupported)
        {
            captureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionFar;
        }
        
        // Set focus mode to Auto
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        // Set exposure point of interest in middle of screen
        if (captureDevice.exposurePointOfInterestSupported)
        {
            [captureDevice setExposurePointOfInterest:CGPointMake(0.5, 0.5)];
        }
        
        // Set exposure mode to continous
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        {
            captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        // Release lock
        [captureDevice unlockForConfiguration];
    }
    
    // Create the capture session and add input
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    NSError* error = nil;
    AVCaptureDeviceInput* captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if ([self.captureSession canAddInput:captureInput])
    {
        [self.captureSession addInput:captureInput];
    }
    
    // Add output
    self.stillCameraOutput = [[AVCapturePhotoOutput alloc] init];
    
    if ([self.captureSession canAddOutput:self.stillCameraOutput])
    {
        [self.captureSession addOutput:self.stillCameraOutput];
    }
    
    // We need to configure the capture connection to give data in landscape orientation
    AVCaptureConnection* connection = [self.stillCameraOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    
    // Add preview layer
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    previewLayer.frame = self.cameraView.bounds;
    
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight)
    {
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else
    {
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    
    [self.cameraView.layer addSublayer:previewLayer];
    
    // We are all set, start the capture session
    [self.captureSession startRunning];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)flashScreen
{
    UIView* flashView = [[UIView alloc] initWithFrame:self.cameraView.bounds];
    flashView.backgroundColor = [UIColor whiteColor];
    [self.cameraView addSubview:flashView];
    
    [UIView animateWithDuration:0.4 animations:^ {
        
        flashView.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        [flashView removeFromSuperview];
        
    }];
}

#pragma mark - Button actions

- (IBAction)captureAction:(id)sender
{
    if (self.cameraBusy)
    {
        return;
    }
    
    self.cameraBusy = YES;
    
    [self flashScreen];
    
    NSDictionary* format = @{AVVideoCodecKey: AVVideoCodecTypeJPEG};
    AVCapturePhotoSettings* settings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
    settings.flashMode = AVCaptureFlashModeOff;
    
    [self.stillCameraOutput capturePhotoWithSettings:settings delegate:self];
}

- (IBAction)exitAction:(id)sender
{
    [self.locationManager stopUpdatingLocation];
    [self.captureSession stopRunning];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if (error == nil)
    {
        // Get the image data and location and add it to the sequence
        
        NSData* imageData = [photo fileDataRepresentation];
        
        MAPLocation* location = [[MAPLocation alloc] init];
        location.location = self.lastLocation;
        
        [self.sequence addImageWithData:imageData date:nil location:location];
    }
    
    self.cameraBusy = NO;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    self.lastLocation = locations.lastObject;
}

@end
