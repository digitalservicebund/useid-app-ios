import Foundation
import Analytics
import OSLog

extension AnalyticsEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        var baseDescription = "\(category) - \(action)"
        if let name {
            baseDescription.append(", name: \(name)")
        } else if let value {
            baseDescription.append(", value: \(value)")
        }
        return baseDescription
    }
}

extension AnalyticsView {
    var debugDescription: String {
        route.isEmpty ? "/" : route.joined(separator: "/")
    }
}

public struct LogAnalyticsClient: AnalyticsClient {
    
    public func track(event: AnalyticsEvent) {
        Logger.analytics.info("Track event: \(event.debugDescription, privacy: .public)")
    }
    
    public func track(view: AnalyticsView) {
        Logger.analytics.info("Track view: \(view.debugDescription, privacy: .public)")
    }
    
    public func dispatch() {}
}
