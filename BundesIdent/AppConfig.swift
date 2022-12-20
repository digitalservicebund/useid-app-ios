import Foundation
import AVFAudio
import Sentry

protocol AppConfigType {
    var sentryDSN: String { get }
    var matomoSiteID: String { get }
    var matomoURL: URL { get }
    
    func configureSentry(_ options: Options)
    func configureAudio()
}

struct AppConfig: AppConfigType {
    let sentryDSN: String
    let matomoURL: URL
    let matomoSiteID: String
    
    init(bundle: Bundle) {
        // Sentry
        // swiftlint:disable force_cast
        let sentryProjectID = bundle.infoDictionary!["SentryProjectID"] as! String
        let sentryPublicKey = bundle.infoDictionary!["SentryPublicKey"] as! String
        let sentryHost = bundle.infoDictionary!["SentryHost"] as! String
        // swiftlint:enable force_cast
        
        sentryDSN = "https://\(sentryPublicKey)@\(sentryHost)/\(sentryProjectID)"
        
        // Matomo
        // swiftlint:disable force_cast
        let matomoHost = bundle.infoDictionary!["MatomoHost"] as! String
        matomoSiteID = bundle.infoDictionary!["MatomoSiteID"] as! String
        // swiftlint:enable force_cast
        
        matomoURL = URL(string: "https://\(matomoHost)/matomo.php")!
    }
    
    func configureSentry(_ options: Options) {
        options.dsn = sentryDSN
#if DEBUG
        options.enabled = false
#endif
#if SENTRY_DEBUG
        options.debug = true
#endif
        options.tracesSampleRate = 1.0
        
        options.enableAutoPerformanceTracking = false
        options.enableAutoBreadcrumbTracking = false
        
        options.enableNetworkBreadcrumbs = false
        options.enableNetworkTracking = false
        
        options.attachViewHierarchy = false
        options.enableUIViewControllerTracking = false
        options.enableUserInteractionTracing = false
        options.enableAppHangTracking = false
        options.beforeSend = {
            guard var context: [String: [String: Any]] = $0.context else { return $0 }
            
            let osKeys = Set(["version", "name"])
            let deviceKeys = Set(["family", "model", "model_id"])
            let appKeys = Set(["app_build", "app_version"])
            let newContext: [String: [String: Any]] = [
                "user info": context["user info"],
                "os": context["os"]?.filter({ osKeys.contains($0.key) }),
                "device": context["device"]?.filter({ deviceKeys.contains($0.key) }),
                "app": context["app"]?.filter({ appKeys.contains($0.key) })
            ].compactMapValues({ $0 })
            
            $0.context = newContext
            return $0
        }
    }
    
    func configureAudio() {
        try? AVAudioSession.sharedInstance()
            .setCategory(.ambient, options: [.mixWithOthers])
    }
}
