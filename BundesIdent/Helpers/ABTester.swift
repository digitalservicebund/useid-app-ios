import Foundation
import Analytics
import UnleashProxyClientSwift

final class Unleash: ABTester {

    init(url: String, clientKey: String, analytics: AnalyticsClient) {
        self.unleash = UnleashClient(unleashUrl: url, clientKey: clientKey)
        self.analytics = analytics
    }

    private let unleash: UnleashClient
    private let analytics: AnalyticsClient
}

struct AlwaysControlABTester: ABTester {
}
