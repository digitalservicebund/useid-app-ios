import MatomoTracker
import Foundation
@testable import Analytics

class MockMatomoTracker: MatomoTrackerProtocol {
    var resetCount = 0
    var dispatchCount = 0
    var trackedViews = [[String]]()
    var trackedEvents = [(category: String, action: String, name: String?, value: Float?)]()
    
    func reset() {
        resetCount += 1
    }
    
    func dispatch() {
        dispatchCount += 1
    }
    
    func track(view: [String], url: URL?) {
        trackedViews.append(view)
    }
    
    func track(eventWithCategory category: String,
               action: String,
               name: String?,
               value: Float?,
               dimensions: [CustomDimension],
               url: URL?) {
        trackedEvents.append((category, action, name, value))
    }
}
