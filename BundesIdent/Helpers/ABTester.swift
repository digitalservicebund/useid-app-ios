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

    private var state: State = .initial

    private enum State {
        case initial
        case loading
        case active
        case disabled
    }

    func prepare() {
        let start = Date()
        state = .loading
        unleash.start(true) { [weak self] error in
            guard let self else { return }
            if let error = error {
                print("👆", "loading error:", error)
                // TODO: track error
            }

            switch self.state {
            case .loading:
                self.state = .active
            case .disabled:
                print("👆", "request took:", Date().timeIntervalSince(start))
                // TODO: track how long the request took
                break
            default:
                break
            }
        }
    }

    func disable() {
        state = .disabled
    }
}

struct AlwaysControlABTester: ABTester {

    func prepare() {}
    func disable() {}
}
