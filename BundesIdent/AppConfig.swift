import Foundation
import AVFAudio

protocol AppConfigType {
    var matomoSiteID: String { get }
    var matomoURL: URL { get }
    
    func configureAudio()
}

struct AppConfig: AppConfigType {
    let matomoURL: URL
    let matomoSiteID: String
    let unleashURL: String
    let unleashClientKey: String
    
    init(bundle: Bundle) {
        // Matomo
        // swiftlint:disable force_cast
        let matomoHost = bundle.infoDictionary!["MatomoHost"] as! String
        matomoSiteID = bundle.infoDictionary!["MatomoSiteID"] as! String
        // swiftlint:enable force_cast
        
        matomoURL = URL(string: "https://\(matomoHost)/matomo.php")!

        // Unleash
        // swiftlint:disable force_cast
        unleashURL = bundle.infoDictionary!["UnleashURL"] as! String
        unleashClientKey = bundle.infoDictionary!["UnleashClientKey"] as! String
        // swiftlint:enable force_cast
    }
    
    func configureAudio() {
        try? AVAudioSession.sharedInstance()
            .setCategory(.ambient, options: [.mixWithOthers])
    }
}
