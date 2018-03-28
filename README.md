# mapillary-sdk-ios

> This repository is the home of the Mapillary iOS SDK.


## Installation with CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Objective-C and Swift, which automates and simplifies the process of using 3rd-party libraries like MapillarySDK in your projects. You can install it with the following command:

`$ gem install cocoapods`


##### Podfile

To integrate MapillarySDK into your Xcode project using CocoaPods, specify it in your Podfile:

```
platform :ios, '11.0'

target 'TargetName' do
	pod 'MapillarySDK'
end
```

Then, run the following command:

`$ pod install`

## Configuration

### Register your app with Mapillary

To use the SDK, you need to obtain a Mapillary `client_id` first. 

1. [Create a Mapillary account](https://www.mapillary.com/signup) if you don't have one already.
2. Create an app at [the Developer page](https://www.mapillary.com/app/settings/developers). 

##### Redirect URL

When you fill in the form, make sure the redirect URL is similar to this:

`com.mycompany.myapp.mapillary`

##### Client id

Copy your client id, you need it to initialize the SDK later.

### Edit your application plist


Add `MapillaryClientId` and `MapillaryRedirectUrl` to your plist file. Below is an example of parts of a plist file.

```
<plist version="1.0">
<dict>
	...
	<key>MapillaryClientId</key>
	<string>YOUR_CLIENT_ID</string>
	...
	<key>MapillaryRedirectUrl</key>
	<string>YOUR_REDIRECT_URL</string>
	...
</dict>
</plist>
```

### App Delegate

Add this to your `AppDelegate.m` file. This is needed to handle background uploading properly.

```
#import <MapillarySDK/MapillarySDK.h>

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{    
    [MAPApplicationDelegate interceptApplication:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}
```

## Documentation

The latest generated documentation can found [here](https://htmlpreview.github.io/?https://github.com/mapillary/mapillary-sdk-ios/blob/master/docs/docs/index.html).

## Example app

There is an example app called [MapillarySDKExample](https://github.com/mapillary/mapillary-sdk-ios/blob/master/MapillarySDKExample) that demonstrates how to use most of the features in the SDK.

## Usage

Below is a quick-start guide to get you started. Refer to the full [docs](https://htmlpreview.github.io/?https://github.com/mapillary/mapillary-sdk-ios/blob/master/docs/docs/index.html) for details.


### Signing in
```
[MAPLoginManager signInFromViewController:self result:^(BOOL success) {            
    
    if (success)
    {
        // Sign in was sucessful
    }
    else
    {
        // Sign in failed
    }        
            
} cancelled:^{
            
    // The user cancelled the sign in process
            
}];
```

### Signing out
```
[MAPLoginManager signOut];
```

### Creating a new sequewnce
```
MAPDevice* device = [MAPDevice thisDevice];
MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:device];    
```

### Adding images to a new sequences

To just add image data to a sequence, use this:

```
[sequence addImageWithData:imageData date:nil location:nil];
```

### Adding locations to a new sequences

To just add a location to a sequence, use this:

```
MAPLocation* location = [[MAPLocation alloc] init];
location.location = self.lastLocation; // From 
[sequence addLocation:location];
```


### Listing sequences
```
[MAPFileManager getSequencesAsync:^(NSArray *sequences) {
        
    // Do something
                    
}];
```

### Uploading sequences

The uploading is a two-part process; image processing and the actual upload. Before an image can be scheduled for upload, it needs to be processed first. What this means is that the necessary information is written into the EXIF of the image, such as the GPS position, your user key, direction etc.

Image processing cannot be performed in the background. Once all images are processed you can put the app in the background and the upload will continue until all images are uploaded.

For testing the upload, use the two properties `testUpload` and `deleteAfterUpload` (only used if `testUpload` is set to `YES`) to configure the uploader:

```
MAPUploadManager* uploadManager = [MAPUploadManager sharedManager];
uploadManager.delegate = self;
uploadManager.testUpload = YES; // Upload to our test server instead
uploadManager.deleteAfterUpload = NO; // Keep the images after upload
[uploadManager processAndUploadSequences:sequencesToUpload];
```

When your app is ready for production, just omit those two lines:

```
MAPUploadManager* uploadManager = [MAPUploadManager sharedManager];
uploadManager.delegate = self;
[uploadManager processAndUploadSequences:sequencesToUpload];
```

### Tracking upload progress

To track the progress of the upload and to be able to update the UI, use `MAPUploadManagerDelegate`:

```
- (void)imageProcessed:(MAPUploadManager *)uploadManager image:(MAPImage *)image uploadStatus:(MAPUploadStatus*)uploadStatus
{
    // Image was processed
}

- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus
{
    // Image was uploaded sucessfully
}

- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image uploadStatus:(MAPUploadStatus*)uploadStatus error:(NSError*)error
{
    // Image failed to uploaded
}

- (void)uploadFinished:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{
	// Upload finished
}

- (void)uploadStopped:(MAPUploadManager*)uploadManager uploadStatus:(MAPUploadStatus*)uploadStatus
{
	// Upload stopped
}
```

## Maintainers
@millenbop, anders@mapillary.com


## Contribute

Give feedback and report bugs on the SDK [here](https://github.com/mapillary/mapillary_sdk_ios/issues).

## License

Copyright (C) Mapillary 2018