# mapillary\_sdk\_ios

> This repository is the home of the Mapillary iOS SDK.


## Install

2. Install and setup CocoaPods if you haven't already.
3. Add `pod mapillary_sdk_ios` to your Podfile.
3. Install with `pod install`.


## Maintainers
@millenbop, anders@mapillary.com


## Contribute

Give feedback and report bugs on the SDK [here](https://github.com/mapillary/mapillary_sdk_ios/issues).


## Documentation

### Client ID

To use the SDK, you need to obtain a Mapillary `client_id` first. 

1. [Create an Mapillary account](https://www.mapillary.com/signup)
2. Obtain the `client_id` from [the Developer page](https://www.mapillary.com/app/settings/developershttps://www.mapillary.com/app/settings/developers)

### Init the SDK

```
#import <Mapillary/Mapillary.h>
...
[Mapillary init:YOUR_CLIENT_ID]
```

## License

Copyright (C) Mapillary 2017