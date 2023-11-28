import Foundation
import mParticle_Apple_SDK
import IterableSDK

class MPKitIterable: NSObject, MPKitProtocol, IterableURLDelegate {

    var configuration: [AnyHashable: Any] = [:]
    var launchOptions: [AnyHashable: Any]?
    var started: Bool = false
    var userAttributes: [String: Any]?
    var userIdentities: [[String: Any]]?
    var mpidEnabled: Bool = false

    static private var customConfig: IterableConfig?
    static private var customUrlDelegate: IterableURLDelegate?
    static private var clickedURL: URL?
    static private var prefersUserId: Bool = false

    class var kitCode: NSNumber {
        return 1003
    }

    class func setCustomConfig(_ config: IterableConfig?) {
        customConfig = config
        customUrlDelegate = config?.urlDelegate
    }

    class func prefersUserId() -> Bool {
        return prefersUserId
    }

    class func setPrefersUserId(_ prefers: Bool) {
        prefersUserId = prefers
    }

    func handleIterableURL(_ url: URL, context: IterableActionContext) -> Bool {
        var result = true

        if MPKitIterable.customUrlDelegate === self {
            print("mParticle -> Error: Iterable urlDelegate was set in custom config but points to the MPKitIterable instance. It should be a different object.")
        } else if let delegate = MPKitIterable.customUrlDelegate, delegate.responds(to: #selector(IterableURLDelegate.handleIterableURL(_:context:))) {
            result = delegate.handleIterableURL(url, context: context)
        } else if MPKitIterable.customUrlDelegate != nil {
            print("mParticle -> Error: Iterable urlDelegate was set in custom config but didn't respond to the selector 'handleIterableURL:context:'")
        }

        let destinationURL = url.absoluteString
        var getAndTrackParams: [String: Any]?
        let clickedUrlString = MPKitIterable.clickedURL?.absoluteString ?? ""
        MPKitIterable.clickedURL = nil

        if destinationURL == nil || clickedUrlString == destinationURL {
            getAndTrackParams = [IterableClickedURLKey: clickedUrlString]
        } else {
            getAndTrackParams = [IterableDestinationURLKey: destinationURL, IterableClickedURLKey: clickedUrlString]
        }

        let attributionResult = MPAttributionResult()
        attributionResult.linkInfo = getAndTrackParams

        _ = kitApi?.onAttributionComplete(with: attributionResult, error: nil)

        return result
    }

    // MARK: - MPKitInstanceProtocol methods

    // MARK: Kit instance and lifecycle
    func didFinishLaunching(with configuration: [AnyHashable: Any]) -> MPKitExecStatus {
        self.configuration = configuration
        start()

        return MPKitExecStatus(code: NSNumber(value: MPKitIterable.kitCode), returnCode: .success)
    }

    func start() {
        static var kitPredicate: dispatch_once_t = 0

        dispatch_once(&kitPredicate, {

            let apiKey = self.configuration["apiKey"] as? String ?? ""
            let apnsProdIntegrationName = self.configuration["apnsProdIntegrationName"] as? String ?? ""
            let apnsSandboxIntegrationName = self.configuration["apnsSandboxIntegrationName"] as? String ?? ""
            let userIdField = self.configuration["userIdField"] as? String ?? ""
            self.mpidEnabled = userIdField == "mpid"

            var config = MPKitIterable.customConfig
            if config == nil {
                config = IterableConfig()
            }
            config?.pushIntegrationName = apnsProdIntegrationName
            config?.sandboxPushIntegrationName = apnsSandboxIntegrationName
            config?.urlDelegate = self

            IterableAPI.initialize(apiKey: apiKey, config: config)
            self.initIntegrationAttributes()

            self.started = true

            dispatch_async(dispatch_get_main_queue(), {
                let userInfo = [mParticleKitInstanceKey: MPKitIterable.kitCode]

                NSNotificationCenter.defaultCenter().postNotificationName(mParticleKitDidBecomeActiveNotification, object: nil, userInfo: userInfo)
            })
        })
    }
    
    func continueUserActivity(_ userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> MPKitExecStatus {
        MPKitIterable.clickedURL = userActivity.webpageURL

        if let clickedURL = MPKitIterable.clickedURL {
            IterableAPI.handleUniversalLink(clickedURL)
        }

        let execStatus = MPKitExecStatus(code: NSNumber(value: MPKitIterable.kitCode), returnCode: .success)
        return execStatus
    }

    func initIntegrationAttributes() {
        let integrationAttributes = [
            "Iterable.sdkVersion": IterableAPI.sdkVersion
        ]
        MParticle.sharedInstance()?.setIntegrationAttributes(integrationAttributes, forKit: MPKitIterable.kitCode)
    }
    
    func getUserEmail(_ user: FilteredMParticleUser) -> String? {
        return user.userIdentities[MPUserIdentityEmail] as? String
    }

    func getCustomerId(_ user: FilteredMParticleUser) -> String? {
        return user.userIdentities[MPUserIdentityCustomerId] as? String
    }

    func onLoginComplete(_ user: FilteredMParticleUser, request: FilteredMPIdentityApiRequest) -> MPKitExecStatus {
        updateIdentity(user)
        return MPKitExecStatus(code: NSNumber(value: type(of: self).kitCode), returnCode: .success)
    }

    func onLogoutComplete(_ user: FilteredMParticleUser, request: FilteredMPIdentityApiRequest) -> MPKitExecStatus {
        updateIdentity(user)
        return MPKitExecStatus(code: NSNumber(value: type(of: self).kitCode), returnCode: .success)
    }

    func onIdentifyComplete(_ user: FilteredMParticleUser, request: FilteredMPIdentityApiRequest) -> MPKitExecStatus {
        updateIdentity(user)
        return MPKitExecStatus(code: NSNumber(value: type(of: self).kitCode), returnCode: .success)
    }

    func getUserId(_ user: FilteredMParticleUser) -> String? {
        var userId: String? = nil
        if mpidEnabled {
            if user.userId.intValue != 0 {
                userId = String(user.userId.intValue)
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
        if let userId = getUserId(user), _prefersUserId {
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
        return kitApi?.getCurrentUser(with: self)
    }

    func setDeviceToken(_ deviceToken: Data) -> MPKitExecStatus {
        IterableAPI.registerToken(deviceToken)
        return MPKitExecStatus(code: NSNumber(value: type(of: self).kitCode), returnCode: .success)
    }
    
    #if os(iOS)
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) -> MPKitExecStatus {
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: {})
        return MPKitExecStatus(code: NSNumber(value: type(of: self).kitCode), returnCode: .success)
    }
    #endif

    func receivedUserNotification(_ userInfo: [AnyHashable: Any]) -> MPKitExecStatus {
        IterableAppIntegration.application(UIApplication.shared, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: { _ in })
        return MPKitExecStatus(code: NSNumber(value: type(of: self).kitCode), returnCode: .success)
    }
    // ... (Remaining methods, unchanged)

    // MARK: - Accessors
    func advertiserId() -> String? {
        var advertiserId: String? = nil
        let MPIdentifierManager = NSClassFromString("ASIdentifierManager")

        if let MPIdentifierManager = MPIdentifierManager {
            let selector = Selector("sharedManager")
            let adIdentityManager = MPIdentifierManager.performSelector(selector)

            let isAdvertisingTrackingEnabledSelector = Selector("isAdvertisingTrackingEnabled")
            let isAdvertisingTrackingEnabled = adIdentityManager.performSelector(isAdvertisingTrackingEnabledSelector)

            if isAdvertisingTrackingEnabled as? Bool ?? false {
                let advertisingIdentifierSelector = Selector("advertisingIdentifier")
                advertiserId = adIdentityManager.performSelector(advertisingIdentifierSelector).UUIDString
            }
        }

        return advertiserId
    }
}
