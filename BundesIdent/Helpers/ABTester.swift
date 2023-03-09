import Foundation
import Analytics
import UnleashProxyClientSwift

final class Unleash: ABTester {

    init(url: String, clientKey: String, analytics: AnalyticsClient, issueTracker: IssueTracker) {
        self.unleash = UnleashClient(unleashUrl: url, clientKey: clientKey)
        self.analytics = analytics
        self.issueTracker = issueTracker
    }

    private let unleash: UnleashClient
    private let analytics: AnalyticsClient
    private let issueTracker: IssueTracker

    private var state: State = .initial

    private enum State {
        case initial
        case loading
        case active
        case disabled
    }

    func prepare() async {
        let start = Date()
        state = .loading

        await withCheckedContinuation { continuation in
            unleash.start() { [weak self] error in
                guard let self else { return continuation.resume() }
                if let error = error {
                    self.trackUnleashBreadcrumb(message: "request failed with error \(error)")
                }

                switch self.state {
                case .loading where error == nil:
                    self.state = .active
                    self.trackUnleashBreadcrumb(message: "activated")
                case .loading:
                    self.state = .disabled
                case .disabled:
                    self.trackUnleashBreadcrumb(message: "request took \(Date().timeIntervalSince(start)) seconds")
                default:
                    break
                }
                return continuation.resume()
            }
        }
    }

    func disable() {
        if state == .loading {
            trackUnleashBreadcrumb(message: "request is taking too long")
        }
        state = .disabled
    }

    private func trackUnleashBreadcrumb(message: String) {
        issueTracker.addInfoBreadcrumb(category: "unleash", message: message)
    }
}

struct AlwaysControlABTester: ABTester {

    func prepare() {}
    func disable() {}
}
