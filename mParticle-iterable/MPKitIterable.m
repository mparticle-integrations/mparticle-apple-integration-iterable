#import "MPKitIterable.h"

@implementation MPKitIterable

@synthesize kitApi = _kitApi;

+ (NSNumber *)kitCode {
    return @1003;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Iterable" className:@"MPKitIterable"];
    [MParticle registerExtension:kitRegister];
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
    NSURL *clickedURL = userActivity.webpageURL;
    
    ITEActionBlock callbackBlock = ^(NSString* destinationURL) {
        NSDictionary *getAndTrackParams = nil;
        NSString *clickedUrlString = clickedURL.absoluteString;
        if (!destinationURL || [clickedUrlString isEqualToString:destinationURL]) {
            getAndTrackParams = [[NSDictionary alloc] initWithObjectsAndKeys: clickedUrlString, IterableClickedURLKey, nil];
        } else {
            getAndTrackParams = [[NSDictionary alloc] initWithObjectsAndKeys: destinationURL, IterableDestinationURLKey, clickedUrlString, IterableClickedURLKey, nil];
        }
        
        MPAttributionResult *attributionResult = [[MPAttributionResult alloc] init];
        attributionResult.linkInfo = getAndTrackParams;
        
        [self->_kitApi onAttributionCompleteWithResult:attributionResult error:nil];
    };
    [IterableAPI getAndTrackDeeplink:clickedURL callbackBlock:callbackBlock];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[MPKitIterable kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end
