#import "MPKitIterable.h"
#import <objc/runtime.h>
#import <objc/message.h>
@import IterableSDK;


@interface MPKitIterable() <IterableURLDelegate>
@end

@implementation MPKitIterable

@synthesize kitApi = _kitApi;
static IterableConfig *_customConfig = nil;
static NSURL *_clickedURL = nil;
static BOOL *prefersUserId = FALSE;

+ (BOOL *)prefersUserId {
    return prefersUserId;
}

+ (void)setPrefersUserId:(BOOL)prefers {
    prefersUserId = &prefers;
}

+ (NSNumber *)kitCode {
    return @1003;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Iterable" className:@"MPKitIterable"];
    [MParticle registerExtension:kitRegister];
}

+ (void)setCustomConfig:(IterableConfig *_Nullable)config {
    _customConfig = config;
}

- (BOOL)handleIterableURL:(NSURL *)url context:(IterableActionContext *)context {
    BOOL result = YES;
    if (_customConfig.urlDelegate != nil && [((NSObject *)_customConfig.urlDelegate) respondsToSelector:@selector(handleIterableURL:context:)]) {
        result = [_customConfig.urlDelegate handleIterableURL:url context: context];
    } else if (_customConfig.urlDelegate != nil) {
        NSLog(@"mParticle -> Error: Iterable urlDelegate was set in custom config but didn't respond to the selector 'handleIterableURL:context:'");
    }

    NSString *destinationURL = url.absoluteString;
    NSDictionary *getAndTrackParams = nil;
    NSString *clickedUrlString = [NSString stringWithString:_clickedURL.absoluteString];
    _clickedURL = nil;
    if (!destinationURL || [clickedUrlString isEqualToString:destinationURL]) {
        getAndTrackParams = [[NSDictionary alloc] initWithObjectsAndKeys: clickedUrlString, IterableClickedURLKey, nil];
    } else {
        getAndTrackParams = [[NSDictionary alloc] initWithObjectsAndKeys: destinationURL, IterableDestinationURLKey, clickedUrlString, IterableClickedURLKey, nil];
    }
    
    MPAttributionResult *attributionResult = [[MPAttributionResult alloc] init];
    attributionResult.linkInfo = getAndTrackParams;

    [self->_kitApi onAttributionCompleteWithResult:attributionResult error:nil];
    return true;
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    
    _configuration = configuration;
    
    [self start];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {
    static dispatch_once_t kitPredicate;
    
    dispatch_once(&kitPredicate, ^{
        
        NSString *apiKey = self.configuration[@"apiKey"];
        NSString *apnsProdIntegrationName = self.configuration[@"apnsProdIntegrationName"];
        NSString *apnsSandboxIntegrationName = self.configuration[@"apnsSandboxIntegrationName"];
        NSString *userIdField = self.configuration[@"userIdField"];
        self.mpidEnabled = [userIdField isEqualToString:@"mpid"];

        IterableConfig *config = _customConfig;
        if (!config) {
            config = [[IterableConfig alloc] init];
        }
        config.pushIntegrationName = apnsProdIntegrationName;
        config.sandboxPushIntegrationName = apnsSandboxIntegrationName;
        config.urlDelegate = self;
        
        [IterableAPI initializeWithApiKey:apiKey config:config];
        [self initIntegrationAttributes];

        self->_started = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

#pragma mark Application
- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler {
    _clickedURL = userActivity.webpageURL;

    if (_clickedURL != nil) {
        [IterableAPI handleUniversalLink:_clickedURL];
    }

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[MPKitIterable kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)initIntegrationAttributes {
    NSDictionary *integrationAttributes = @{
            @"Iterable.sdkVersion": IterableAPI.sdkVersion
    };
    [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:MPKitIterable.kitCode];
}

- (NSString *)getUserEmail:(FilteredMParticleUser *)user {
    return user.userIdentities[@(MPUserIdentityEmail)];
}

- (NSString *)getCustomerId:(FilteredMParticleUser *)user {
    return user.userIdentities[@(MPUserIdentityCustomerId)];
}

- (MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    [self updateIdentity:user];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)onLogoutComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request {
    [self updateIdentity:user];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    [self updateIdentity:user];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (NSString *)getPlaceholderEmail:(NSString *)userId {
    if (userId.length > 0) {
        return [NSString stringWithFormat:@"%@@placeholder.email", userId];
    } else {
        return nil;
    }
}

- (NSString *)getUserId:(FilteredMParticleUser *)user {
    NSString *id = nil;
    if (self.mpidEnabled) {
        if (user.userId.longValue != 0) {
            id = user.userId.stringValue;
        }
    } else {
        id = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] lowercaseString];

        if (!id.length) {
            id = [[self advertiserId] lowercaseString];
        }

        if (!id.length) {
            id = [self getCustomerId:user];
        }

        if (!id.length) {
            id = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
        }
    }
    return id;
}

- (void)updateIdentity:(FilteredMParticleUser *)user {
    NSString *userId = [self getUserId:user];
    
    if (prefersUserId) {
        [IterableAPI setUserId:userId];
        return;
    }
    
    NSString *email = [self getUserEmail:user];
    NSString *placeholderEmail = [self getPlaceholderEmail:userId];
    
    if (email != nil && email.length > 0) {
        [IterableAPI setEmail:email];
    } else if (placeholderEmail != nil && placeholderEmail.length > 0) {
        [IterableAPI setEmail:placeholderEmail];
    } else {
        // No identifier, log out
        [IterableAPI setEmail:nil];
    }
}

- (FilteredMParticleUser *)currentUser {
    return [[self kitApi] getCurrentUserWithKit:self];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [IterableAPI registerToken:deviceToken];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (MPKitExecStatus *)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0)) {
    [IterableAppIntegration userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:^{}];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}
#endif
 
- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [IterableAppIntegration application:UIApplication.sharedApplication didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

#pragma mark Accessors
- (NSString *)advertiserId {
    NSString *advertiserId = nil;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];

        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL advertisingTrackingEnabled = ((BOOL (*)(id, SEL))objc_msgSend)(adIdentityManager, selector);
        if (advertisingTrackingEnabled) {
            selector = NSSelectorFromString(@"advertisingIdentifier");
            advertiserId = [[adIdentityManager performSelector:selector] UUIDString];
        }
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }

    return advertiserId;
}

@end
