import MatomoTracker
import Foundation

public final class MatomoAnalyticsClient: AnalyticsClient {
    private let tracker: MatomoTrackerProtocol
    private let sessionTimeout: TimeInterval
    
    private var lastRoute: [String]?
    private var lastActivity: Date?
    
    public convenience init(siteId: String, baseURL: URL) {
        self.init(tracker: MatomoTracker(siteId: siteId, baseURL: baseURL))
    }
    
    init(tracker: MatomoTrackerProtocol, sessionTimeout: TimeInterval = 1_800) {
        self.tracker = tracker
        self.sessionTimeout = sessionTimeout
    }
        
    public func track(event: AnalyticsEvent) {
        updateSession()
        tracker.track(eventWithCategory: event.category,
                      action: event.action,
                      name: event.name,
                      value: event.value,
                      dimensions: [],
                      url: nil)
    }
    
    public func track(view: AnalyticsView) {
        let route = view.route
        guard route != lastRoute else { return }
        lastRoute = route
        
        updateSession()
        tracker.track(view: route, url: nil)
    }
    
    public func dispatch() {
        tracker.dispatch()
    }
    
    private func updateSession() {
        defer { lastActivity = Date() }
        guard abs(lastActivity?.timeIntervalSinceNow ?? .infinity) > sessionTimeout else { return }
        
        tracker.reset()
    }
}

protocol MatomoTrackerProtocol {
    func reset()
    func dispatch()
    func track(view: [String], url: URL?)
    func track(eventWithCategory category: String,
               action: String,
               name: String?,
               value: Float?,
               dimensions: [CustomDimension],
               url: URL?)
}

extension MatomoTracker: MatomoTrackerProtocol {}
