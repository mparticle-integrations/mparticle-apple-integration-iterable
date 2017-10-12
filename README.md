# mParticle Apple Kit Library

A kit is an extension to the core [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk). A kit works as a bridge between the mParticle SDK and a partner SDK. It abstracts the implementation complexity, simplifying the implementation for developers.

A kit takes care of initializing and forwarding information depending on what you've configured in [your app's dashboard](https://app.mparticle.com), so you just have to decide which kits you may use prior to submission to the App Store. You can easily include all of the kits, none of the kits, or individual kits – the choice is yours.

[![CocoaPods compatible](http://img.shields.io/badge/CocoaPods-compatible-brightgreen.png)](https://cocoapods.org/?q=mparticle)


## Installation

Please refer to installation instructions in the core mParticle Apple SDK [README](https://github.com/mParticle/mparticle-apple-sdk#get-the-sdk), or check out our [SDK Documentation](http://docs.mparticle.com/#mobile-sdk-guide) site to learn more.

## Deep-linking

Set the property `onAttributionComplete:` on `MParticleOptions` when initializing the mParticle SDK. A copy of your block will be invoked to provide the respective information:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"<<Your app key>>" secret:@"<<Your app secret>>"];
    options.onAttributionComplete = ^void (MPAttributionResult *_Nullable attributionResult, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Attribution fetching for kitCode=%@ failed with error=%@", error.userInfo[mParticleKitInstanceKey], error);
            return;
        }

        NSLog(@"Attribution fetching for kitCode=%@ completed with linkInfo: %@", attributionResult.kitCode, attributionResult.linkInfo);

    }
    [[MParticle sharedInstance] startWithOptions:options];

    return YES;
}
```

A copy of your block will be passed an attributionResult containing a linkInfo dictionary with the following data. Use the `IterableDestinationURLKey` to navigate to your desired location within the app.

```json
{
	"IterableDestinationURLKey" : "<the destination url>",
	"IterableClickedURLKey" : "<the clicked url>"
}

```

## Support

Questions? Give us a shout at <support@mparticle.com>


## License

This mParticle Apple Kit is available under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See the LICENSE file for more info.
