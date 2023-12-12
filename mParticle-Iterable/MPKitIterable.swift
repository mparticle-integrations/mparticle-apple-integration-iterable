import Foundation
import mParticle_Apple_SDK
import IterableSDK

@objcMembers public class MPKitIterable: NSObject, MPKitProtocol, IterableURLDelegate {
    
    private var _kitApi: MPKitAPI?
    public var configuration: [AnyHashable: Any] = [:]
    public var launchOptions: [AnyHashable: Any]?
    public var started: Bool = false
    public var userAttributes: [String: Any]?
    public var userIdentities: [[String: Any]]?
    public var mpidEnabled: Bool = false
    
    static private var customConfig: IterableConfig?
    static private var customUrlDelegate: IterableURLDelegate?
    static private var clickedURL: URL?
    static private var _prefersUserId: Bool = false
    
    public static func setCustomConfig(_ config: IterableConfig?) {
        customConfig = config
        customUrlDelegate = config?.urlDelegate
    }
    
    public static func prefersUserId() -> Bool {
        return _prefersUserId
    }
    
    public static func kitCode() -> NSNumber {
        return 1003
    }
    
    public static func setPrefersUserId(_ prefers: Bool) {
        _prefersUserId = prefers
    }
    
    public func handle(iterableURL url: URL, inContext context: IterableSDK.IterableActionContext) -> Bool {
        var result = true
        
        if MPKitIterable.customUrlDelegate === self {
            print("mParticle -> Error: Iterable urlDelegate was set in custom config but points to the MPKitIterable instance. It should be a different object.")
        } else if let customUrlDelegate = MPKitIterable.customUrlDelegate as? NSObject, customUrlDelegate.responds(to: #selector(IterableURLDelegate.handle(iterableURL:inContext:))) {
            if let customResult = customUrlDelegate.perform(#selector(IterableURLDelegate.handle(iterableURL:inContext:)), with: url, with: context)?.takeUnretainedValue() as? Bool {
                result = customResult
            }
        } else if MPKitIterable.customUrlDelegate != nil {
            print("mParticle -> Error: Iterable urlDelegate was set in custom config but didn't respond to the selector 'handleIterableURL:context:'")
        }
        
        let destinationURL = url.absoluteString
        var getAndTrackParams: [String: Any]?
        let clickedUrlString = MPKitIterable.clickedURL?.absoluteString ?? ""
        MPKitIterable.clickedURL = nil
        
        if destinationURL.isEmpty || clickedUrlString == destinationURL {
            getAndTrackParams = [IterableClickedURLKey: clickedUrlString]
        } else {
            getAndTrackParams = [IterableDestinationURLKey: destinationURL, IterableClickedURLKey: clickedUrlString]
        }
        
        let attributionResult = MPAttributionResult()
        attributionResult.linkInfo = getAndTrackParams ?? [:]
        
        _ = _kitApi?.onAttributionComplete(with: attributionResult, error: nil)
        
        return result
    }
    
    // MARK: - MPKitInstanceProtocol methods
    
    // MARK: Kit instance and lifecycle
    public func didFinishLaunching(withConfiguration configuration: [AnyHashable: Any]) -> MPKitExecStatus {
        self.configuration = configuration
        start()
        return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
    }
    
    public func start() {
        struct OnceToken {
            static var token = false
        }
        
        if !OnceToken.token {
            if let apiKey = self.configuration["apiKey"] as? String,
               let apnsProdIntegrationName = self.configuration["apnsProdIntegrationName"] as? String,
               let apnsSandboxIntegrationName = self.configuration["apnsSandboxIntegrationName"] as? String,
               let userIdField = self.configuration["userIdField"] as? String {
                
                self.mpidEnabled = userIdField == "mpid"
                
                var config = Self.customConfig
                if config == nil {
                    config = IterableConfig()
                }
                
                config?.pushIntegrationName = apnsProdIntegrationName
                config?.sandboxPushIntegrationName = apnsSandboxIntegrationName
                config?.urlDelegate = self
                
                if let config = config {
                    IterableAPI.initialize(apiKey: apiKey, config: config)
                    initIntegrationAttributes()
                    
                    self.started = true
                    
                    DispatchQueue.main.async {
                        let userInfo = [mParticleKitInstanceKey: MPKitIterable.kitCode()]
                        
                        NotificationCenter.default.post(name: NSNotification.Name(NSNotification.Name.mParticleKitDidBecomeActive.rawValue),
                                                        object: nil,
                                                        userInfo: userInfo)
                    }
                }
            }
        }
        
        func continueUserActivity(_ userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> MPKitExecStatus {
            MPKitIterable.clickedURL = userActivity.webpageURL
            
            if let clickedURL = MPKitIterable.clickedURL {
                IterableAPI.handle(universalLink: clickedURL)
            }
            
            return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
        }
        
        func initIntegrationAttributes() {
            let integrationAttributes = [
                "Iterable.sdkVersion": IterableAPI.sdkVersion
            ]
            MParticle.sharedInstance().setIntegrationAttributes(integrationAttributes, forKit: MPKitIterable.kitCode())
        }
        
        func getUserEmail(_ user: FilteredMParticleUser) -> String? {
            return user.userIdentities[NSNumber(value: MPUserIdentity.email.rawValue)]
        }
        
        func getCustomerId(_ user: FilteredMParticleUser) -> String? {
            return user.userIdentities[NSNumber(value: MPUserIdentity.customerId.rawValue)]
        }
        
        func onLoginComplete(_ user: FilteredMParticleUser, request: FilteredMPIdentityApiRequest) -> MPKitExecStatus {
            updateIdentity(user)
            return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
        }
        
        func onLogoutComplete(_ user: FilteredMParticleUser, request: FilteredMPIdentityApiRequest) -> MPKitExecStatus {
            updateIdentity(user)
            return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
        }
        
        func onIdentifyComplete(_ user: FilteredMParticleUser, request: FilteredMPIdentityApiRequest) -> MPKitExecStatus {
            updateIdentity(user)
            return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
        }
        
        func getUserId(_ user: FilteredMParticleUser) -> String? {
            var userId: String? = nil
            if mpidEnabled {
                if user.userId != 0 {
                    userId = user.userId.stringValue
                }
            } else {
                userId = UIDevice.current.identifierForVendor?.uuidString.lowercased()
                
                if userId?.isEmpty ?? true {
                    userId = advertiserId()?.lowercased()
                }
                
                if userId?.isEmpty ?? true {
                    userId = getCustomerId(user)
                }
                
                if userId?.isEmpty ?? true {
                    userId = MParticle.sharedInstance().identity.deviceApplicationStamp
                }
            }
            return userId
        }
        
        func getPlaceholderEmail(_ userId: String?) -> String? {
            guard let userId = userId, !userId.isEmpty else {
                return nil
            }
            return "\(userId)@placeholder.email"
        }
        
        func updateIdentity(_ user: FilteredMParticleUser) {
            if let userId = getUserId(user), MPKitIterable._prefersUserId {
                IterableAPI.setUserId(userId)
                return
            }
            
            let email = getUserEmail(user)
            let placeholderEmail = getPlaceholderEmail(getUserId(user))
            
            if let email = email, !email.isEmpty {
                IterableAPI.setEmail(email)
            } else if let placeholderEmail = placeholderEmail, !placeholderEmail.isEmpty {
                IterableAPI.setEmail(placeholderEmail)
            } else {
                // No identifier, log out
                IterableAPI.setEmail(nil)
            }
        }
        
        func currentUser() -> FilteredMParticleUser? {
            return _kitApi?.getCurrentUser(withKit: self)
        }
        
        func setDeviceToken(_ deviceToken: Data) -> MPKitExecStatus {
            IterableAPI.register(token: deviceToken)
            return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
        }
        
#if os(iOS)
        @available(iOS 10.0, *)
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) -> MPKitExecStatus {
            IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: {})
            return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
        }
#endif
        
        func receivedUserNotification(_ userInfo: [AnyHashable: Any]) -> MPKitExecStatus {
            IterableAppIntegration.application(UIApplication.shared, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: { _ in })
            return MPKitExecStatus(sdkCode: MPKitIterable.kitCode(), returnCode: .success)
        }
        
        // MARK: - Accessors
        func advertiserId() -> String? {
            var advertiserId: String?

            if let MPIdentifierManagerClass = NSClassFromString("ASIdentifierManager") as? NSObject.Type {
                let selector = NSSelectorFromString("sharedManager")
                if let adIdentityManager = MPIdentifierManagerClass.perform(selector)?.takeUnretainedValue() as? NSObject {
                    let isAdvertisingTrackingEnabledSelector = NSSelectorFromString("isAdvertisingTrackingEnabled")
                    if let isAdvertisingTrackingEnabled = adIdentityManager.perform(isAdvertisingTrackingEnabledSelector)?.takeUnretainedValue() as? NSNumber, isAdvertisingTrackingEnabled.boolValue {
                        let advertisingIdentifierSelector = NSSelectorFromString("advertisingIdentifier")
                        if let advertisingIdentifier = adIdentityManager.perform(advertisingIdentifierSelector)?.takeUnretainedValue() as? NSUUID {
                            advertiserId = advertisingIdentifier.uuidString
                        }
                    }
                }
            }

            return advertiserId
        }


    }
}
