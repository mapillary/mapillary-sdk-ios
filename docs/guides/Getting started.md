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

To use the SDK, you need to register your application and obtain a Mapillary client id.

1. [Create a Mapillary account](https://www.mapillary.com/signup) if you don't have one already.
2. Create an app at [the Developer page](https://www.mapillary.com/app/settings/developers). 

##### Callback URL

When you fill in the form, make sure the callback URL is similar to this:

`com.mycompany.myapp.mapillary`

##### Scope

Make sure to check the permissions your app needs access to. If unsure, check all of them. Make a note of this as you have to provide the same scope when authenticating later in the app.

##### Client id

After you have registered your application, copy your client id, you need it to initialize the SDK later.

### Edit your application plist


Add `MapillaryClientId` and `MapillaryCallbackUrl` to your plist file. Below is an example of parts of a plist file.

```
<plist version="1.0">
<dict>
	...
	<key>MapillaryClientId</key>
	<string>YOUR_CLIENT_ID</string>
	...
	<key> MapillaryCallbackUrl</key>
	<string>YOUR_CALLBACK_URL</string>
	...
</dict>
</plist>
```

### Add this to to your app delegate

In order for background uploads to work properly, you need to add this:

##### Swift

```
func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
	MAPApplicationDelegate.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
}
```

##### Objective-C
```
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{    
    [MAPApplicationDelegate application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}
```

## Usage

Below is a quick-start guide to get you started. Refer to the full [docs](https://htmlpreview.github.io/?https://github.com/mapillary/mapillary-sdk-ios/blob/master/docs/docs/index.html) for details.


### Signing in

You need to specify the permissions (as a bit mask) that your app needs access to. Use the same as when you registered your app.

##### Swift

```
MAPLoginManager.signIn(from: self, scope: MAPScopeMask.all, result: { (success) in
            
    if success
    {
        // Sign in was sucessful
    }
    else
    {
        // Sign in failed
    }
            
}) {
            
    // The user cancelled the sign in process
            
}
```

##### Objective-C

```
[MAPLoginManager signInFromViewController:self scope:MAPScopeMaskAll result:^(BOOL success) {            
    
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

##### Swift
```
MAPLoginManager.signOut()
```

##### Objective-C
```
[MAPLoginManager signOut];
```

### Creating a new sequewnce

##### Swift
```
let device = MAPDevice.thisDevice() as! MAPDevice
let sequence = MAPSequence.init(device: device)
```

##### Objective-C
```
MAPDevice* device = [MAPDevice thisDevice];
MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:device];    
```

### Adding images to a new sequences

To just add image data to a sequence, use this:

##### Swift
```
sequence.addImage(with: imageData, date: nil, location: nil)
```

##### Objective-C
```
[sequence addImageWithData:imageData date:nil location:nil];
```

### Adding locations to a new sequences

To just add a location to a sequence, use this:

##### Swift
```
let location = MAPLocation.init()
location.location = lastLocation // From CLLocationManager
sequence.addLocation(location)
```

##### Objective-C
```
MAPLocation* location = [[MAPLocation alloc] init];
location.location = lastLocation; // From CLLocationManager
[sequence addLocation:location];
```


### Listing sequences

##### Swift
```
MAPFileManager.getSequencesAsync(true) { (sequences) in

    // Do something
    
}
```

##### Objective-C
```
[MAPFileManager getSequencesAsync:true done:^(NSArray *sequences) {
        
    // Do something
                    
}];
```

### Uploading sequences

The uploading is a two-part process; image processing and the actual upload. Before an image can be scheduled for upload, it needs to be processed first. What this means is that the necessary information is written into the EXIF of the image, such as the GPS position, your user key, direction etc.

Image processing cannot be performed in the background. Once all images are processed you can put the app in the background and the upload will continue until all images are uploaded.

For testing the upload, use the two properties `testUpload` and `deleteAfterUpload` (only used if `testUpload` is set to `YES`) to configure the uploader:

##### Swift
```
let uploadManager = MAPUploadManager.shared()
uploadManager.delegate = self
uploadManager.testUpload = true // Upload to our test server instead
uploadManager.deleteAfterUpload = false // Keep the images after upload
uploadManager.processAndUploadSequences(sequencesToUpload)
```

##### Objective-C
```
MAPUploadManager* uploadManager = [MAPUploadManager sharedManager];
uploadManager.delegate = self;
uploadManager.testUpload = YES; // Upload to our test server instead
uploadManager.deleteAfterUpload = NO; // Keep the images after upload
[uploadManager processAndUploadSequences:sequencesToUpload];
```

When your app is ready for production, just omit those two lines:

##### Swift
```
let uploadManager = MAPUploadManager.shared()
uploadManager.delegate = self
uploadManager.processAndUploadSequences(sequencesToUpload)
```

##### Objective-C
```
MAPUploadManager* uploadManager = [MAPUploadManager sharedManager];
uploadManager.delegate = self;
[uploadManager processAndUploadSequences:sequencesToUpload];
```

### Tracking images processsing and upload progress

To track the progress of the image processing and/or upload and to be able to update the UI, use `MAPUploadManagerDelegate`:

##### Swift
```

func imageProcessed(_ uploadManager: MAPUploadManager!, image: MAPImage!, status: MAPUploadManagerStatus!)
{
	// Image was processed
}
    
func processingFinished(_ uploadManager: MAPUploadManager!, status: MAPUploadManagerStatus!)
{
    // Image processing finished
}

func processingStopped(_ uploadManager: MAPUploadManager!, status: MAPUploadManagerStatus!)
{
    // Image processing was stopped
}

func imageUploaded(_ uploadManager: MAPUploadManager!, image: MAPImage!, status: MAPUploadManagerStatus!)
{
   // Image was uploaded sucessfully
}

func imageFailed(_ uploadManager: MAPUploadManager!, image: MAPImage!, status: MAPUploadManagerStatus!, error: Error!) 
{
	// Image failed to uploaded  
}
    
func uploadedData(_ uploadManager: MAPUploadManager!, bytesSent: Int64, status: MAPUploadManagerStatus!) 
{
	// Uploaded bytesSent bytes
}

func uploadFinished(_ uploadManager: MAPUploadManager!, status: MAPUploadManagerStatus!)
{
	// Upload finished
}

func uploadStopped(_ uploadManager: MAPUploadManager!, status: MAPUploadManagerStatus!) 
{
	// Upload stopped    
}

```

##### Objective-C
```
- (void)imageProcessed:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status
{
    // Image was processed
}

- (void)processingFinished:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
    // Image processing finished
}

- (void)processingStopped:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
    // Image processing was stopped
}

- (void)imageUploaded:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status
{
    // Image was uploaded sucessfully
}

- (void)imageFailed:(MAPUploadManager*)uploadManager image:(MAPImage*)image status:(MAPUploadManagerStatus*)status error:(NSError*)error
{
    // Image failed to uploaded
}

- (void)uploadedData:(MAPUploadManager*)uploadManager bytesSent:(int64_t)bytesSent status:(MAPUploadManagerStatus*)status
{
	// Uploaded bytesSent bytes
}

- (void)uploadFinished:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
	// Upload finished
}

- (void)uploadStopped:(MAPUploadManager*)uploadManager status:(MAPUploadManagerStatus*)status
{
	// Upload stopped
}
```

## Documentation

The latest generated documentation can found [here](https://htmlpreview.github.io/?https://github.com/mapillary/mapillary-sdk-ios/blob/master/docs/docs/getting-started.html).

## Example app

There is an example app called [MapillarySDKExample](https://github.com/mapillary/mapillary-sdk-ios/blob/master/MapillarySDKExample) that demonstrates most of the features in the SDK.

## Maintainers
@millenbop, anders@mapillary.com


## Contribute

Give feedback and report bugs on the SDK [here](https://github.com/mapillary/mapillary_sdk_ios/issues).

## License

Copyright (C) Mapillary 2018