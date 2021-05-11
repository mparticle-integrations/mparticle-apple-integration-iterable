## Iterable Kit Integration

This repository contains the [Iterable](https://iterable.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

### Adding the integration

1. Add the kit dependency to your app's Podfile or Cartfile:

    ```
    pod 'mParticle-Iterable', '~> 8.0.2'
    ```

    OR

    ```
    github "mparticle-integrations/mparticle-apple-integration-iterable" ~> 8.0.2
    ```

2. Follow the mParticle iOS SDK [quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app, and verify that you see `"Included kits: { Iterable }"` in your Xcode console 

> (This requires your mParticle log level to be at least Debug)

3. Reference mParticle's integration docs below to enable the integration.


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

### Documentation

[Iterable integration](https://docs.mparticle.com/integrations/iterable/event/)

### License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
