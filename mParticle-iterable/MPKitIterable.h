#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
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

@end
