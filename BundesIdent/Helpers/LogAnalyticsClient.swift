import Foundation
import Analytics
import OSLog

extension AnalyticsEvent: CustomDebugStringConvertible {
    public var debugDescription: String {
        var baseDescription = "\(category) - \(action)"
        if let name = name {
            baseDescription.append(", name: \(name)")
        } else if let value = value {
            baseDescription.append(", value: \(value)")
        }
        return baseDescription
    }
}

extension AnalyticsView {
    var debugDescription: String {
        return route.isEmpty ? "/" : route.joined(separator: "/")
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
