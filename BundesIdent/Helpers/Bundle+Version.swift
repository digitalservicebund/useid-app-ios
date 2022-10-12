import Foundation

extension Bundle {
    
    var version: String {
        let shortVersionString = infoDictionary?["CFBundleShortVersionString"] as? String
        return shortVersionString!
    }
    
    var buildNumber: Int {
        // swiftlint:disable:next force_cast
        let buildNumberAsString = object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        return Int(buildNumberAsString)!
    }
}
