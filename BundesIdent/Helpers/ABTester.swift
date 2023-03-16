import Foundation
import Analytics
import UnleashProxyClientSwift

enum ABTest: CaseIterable {

    var rawValue: String {
        switch self {
        }
    }
}

final class Unleash: ABTester {

    init(url: String, clientKey: String, analytics: AnalyticsClient, issueTracker: IssueTracker) {
        unleash = .init(unleashUrl: url, clientKey: clientKey, refreshInterval: .max, appName: "bundesIdent.iOS")
        unleash.context["supportedToggles"] = ABTest.allCases.map(\.rawValue).joined(separator: ",")
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

        do {
            try await unleash.start()
            switch state {
            case .loading:
                state = .active
            case .disabled:
                issueTracker.capture(error: UnleashError.requestTookTooLong((Date().timeIntervalSince(start))))
            default:
                break
            }

        } catch let error as NSError {
            if state == .loading {
                state = .disabled
            }
            issueTracker.capture(error: UnleashError.requestFailed(error))
        }
    }

    func disable() {
        state = .disabled
    }

    func isVariationActivated(for test: ABTest) -> Bool {
        guard state == .active, unleash.isEnabled(name: test.rawValue) else { return false }

        let variantName = unleash.getVariant(name: test.rawValue).name
        analytics.track(event: .init(category: "abtesting", action: test.rawValue, name: variantName))
        issueTracker.addInfoBreadcrumb(category: "abtest", message: "\(test.rawValue): \(variantName)")
        return variantName == "variation"
    }

    private func trackUnleashBreadcrumb(message: String) {
        issueTracker.addInfoBreadcrumb(category: "unleash", message: message)
    }
}

private enum UnleashError: CustomNSError {
    case requestTookTooLong(TimeInterval)
    case requestFailed(NSError)
}

struct AlwaysControlABTester: ABTester {

    func prepare() {}
    func disable() {}

    func isVariationActivated(for test: ABTest) -> Bool {
        false
    }
}

extension UnleashClient {

    func start() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            start { error in
                if let error {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
