import Foundation
@testable import Analytics

class FakeAnalyticsView: AnalyticsView {
    var route: [String]
    
    init(route: [String] = ["fake-screen"]) {
        self.route = route
    }
}

extension AnalyticsEvent {
    static var fake: Self {
        AnalyticsEvent(category: "category", action: "action")
    }
}
