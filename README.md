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
2. Create an app at [the Developer page](https://www.mapillary.com/app/settings/developershttps://www.mapillary.com/app/settings/developers). 

##### Redirect URL

When you fill in the form, make sure the redirect URL is similar to this:

`com.mycompany.myapp.mapillary://`

> The `://` at the end is very important!

##### client_id

Copy your `client_id`, you need it to initialize the SDK later.

### Edit your application plist

Now you need to add a custom URL scheme to your app. This is needed so that after authentication in the browser, your app can get focus again. Enter the same scheme as you provided in the redirect URL previously (but without ://). 

You also need to add `MapillaryClientId` and `MapillaryRedirectUrl` to the plist.

Below is an example of parts of a plist file.

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
				<string>YOUR_REDIRECT_URL</string>
			</array>
		</dict>
	</array>
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

Add this to your `AppDelegate.m` file:

```
#import <MapillarySDK/MapillarySDK.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return [MAPApplicationDelegate application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [MAPApplicationDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}
```

## Usage


### Signing in
```
[MAPLoginManager signIn:^(BOOL success) {
                
    if (success)
    {
        NSLog(@"Sign in was a success");
    }
    else
    {
        NSLog(@"Sign in failed");
    }                        

}];
```

### Signing out
```
[MAPLoginManager signOut];
```

## Maintainers
@millenbop, anders@mapillary.com


## Contribute

Give feedback and report bugs on the SDK [here](https://github.com/mapillary/mapillary_sdk_ios/issues).

## License

Copyright (C) Mapillary 2017