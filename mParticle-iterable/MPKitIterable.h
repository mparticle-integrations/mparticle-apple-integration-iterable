#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle.h>
    #import <mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>
#else
    #import "mParticle.h"
    #import "mParticle_Apple_SDK-Swift.h"
#endif

#import "IterableMPHelper.h"

@class IterableConfig;

@interface MPKitIterable : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;
@property (nonatomic, readwrite) BOOL mpidEnabled;

/**
 * Set a custom config to be used when initializing Iterable SDK
 * @param config `IterableConfig` instance with configuration data for Iterable SDK
 */
+ (void)setCustomConfig:(IterableConfig *_Nullable)config;
+ (void)setCustomConfigObject:(id _Nullable)config;

/**
 * Declare whether or not to prefer user id in API calls to Iterable. If `YES`, the kit will not
 * set an email or create a placeholder.email address
 */
+ (void)setPrefersUserId:(BOOL)prefers;
+ (BOOL)prefersUserId;

@end
