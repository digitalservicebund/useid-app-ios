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

    func prepare() async {
        let start = Date()
        state = .loading

        await withCheckedContinuation { continuation in
            unleash.start() { [weak self] error in
                guard let self else { return continuation.resume() }
                if let error = error {
                    print("👆", "loading error:", error)
                    // TODO: track error
                }

                switch self.state {
                case .loading where error == nil:
                    self.state = .active
                case .loading:
                    self.state = .disabled
                case .disabled:
                    print("👆", "request took:", Date().timeIntervalSince(start))
                    // TODO: track how long the request took
                    break
                default:
                    break
                }
                return continuation.resume()
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
