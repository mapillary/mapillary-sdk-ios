# mapillary-sdk-ios

> This repository is the home of the Mapillary iOS SDK.


## Installation with CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Objective-C and Swift, which automates and simplifies the process of using 3rd-party libraries like MapillarySDK in your projects. You can install it with the following command:

`$ gem install cocoapods`


##### Podfile

To integrate MapillarySDK into your Xcode project using CocoaPods, specify it in your Podfile:

```
platform :ios, '8.0'

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
2. Create an app at [the Developer page](https://www.mapillary.com/app/settings/developershttps://www.mapillary.com/app/settings/developers). 

##### Redirect URL

When you fill in the form, make sure the redirect URL is on this format:

`com.mycompany.myapp.mapillary://`

> The `://` at the end is very important!

##### client_id

Copy your `client_id`, you need it to initialize the SDK later.

### Custom URL scheme

Now you need to add a custom URL scheme to your app. This is needed so that after authentication in the browser, your app can get focus again. Enter the same scheme as you provided in the redirect URL previously. Below is an example of an plist.

```
<plist version="1.0">
<dict>
	...
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>com.mycompany.myapp.mapillary</string>
			</array>
		</dict>
	</array>
	...
</dict>
</plist>
```

### App Delegate

Add this to your `AppDelegate.m` file:

```
#import <MapillarySDK/MapillarySDK.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[MapillarySDK initWithClientId:YOUR_CLIENT_ID andRedirectUrl:YOUR_REDIRECT_URL];
	return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{    
	return [MAPLoginManager finishSignIn:url];
}
```

## Usage


### Signing in
```
[MAPLoginManager signIn];
```

### Creating a new sequence
```
MAPDevice* device = [[MAPDevice alloc] init];
device.name = @"iPhone7,2";
device.make = @"Apple";
device.model = @"iPhone 6";
    
MAPSequence* sequence = [[MAPSequence alloc] initWithDevice:device];
```

### Adding images and position data from GPS
```
NSData* imageData = [NSData from camera or similar];

MAPLocation* location = [[MAPLocation alloc] init];
location.location = <CLLocation from GPS>;
location.heading = <CLHeading from GPS>;           

[sequence addImageWithData:imageData date:[NSDate date] location:location];
```

### Adding images and position data from a GPX file recorded with another app
```
NSData* imageData = [NSData from camera or similar];
        
[sequence addImageWithData:imageData date:[NSDate date] location:nil];
[sequence addGpx:<path to GPX file>];
```

### Uploading a sequence
```
[MAPUploadManager uploadSequences:@[sequence]];
```

TODO

## Maintainers
@millenbop, anders@mapillary.com


## Contribute

Give feedback and report bugs on the SDK [here](https://github.com/mapillary/mapillary_sdk_ios/issues).

## License

Copyright (C) Mapillary 2017