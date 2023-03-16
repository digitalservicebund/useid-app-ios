import Foundation
import Analytics
import UnleashProxyClientSwift

enum ABTest: CaseIterable {
#if PREVIEW
    case test
#endif

    var name: String {
        switch self {
#if PREVIEW
        case .test: return "test"
#endif
        }
    }
}

final class UnleashManager: ABTester {

    convenience init(url: String, clientKey: String, analytics: AnalyticsClient, issueTracker: IssueTracker) {
        let unleashClient = UnleashClient(unleashUrl: url, clientKey: clientKey, refreshInterval: .max, appName: "bundesIdent.iOS")
        self.init(unleashClient: unleashClient, analytics: analytics, issueTracker: issueTracker)
    }

    init(unleashClient: UnleashClientWrapper, analytics: AnalyticsClient, issueTracker: IssueTracker) {
        self.unleashClient = unleashClient
        self.analytics = analytics
        self.issueTracker = issueTracker

        unleashClient.context["supportedToggles"] = ABTest.allCases.map(\.name).filter { $0 != "test" }.joined(separator: ",")
    }

    private let unleashClient: UnleashClientWrapper
    private let analytics: AnalyticsClient
    private let issueTracker: IssueTracker

    private(set) var state: State = .initial

    enum State {
        case initial
        case loading
        case active
        case disabled
    }

    func prepare() async {
        let start = Date()
        state = .loading

        do {
            try await unleashClient.start()
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

    func isVariationActivated(for test: ABTest?) -> Bool {
        guard state == .active, let test = test, let variantName = unleashClient.variantName(forTestName: test.name)
        else { return false }

        analytics.track(event: .init(category: "abtesting", action: test.name, name: variantName))
        issueTracker.addInfoBreadcrumb(category: "abtest", message: "\(test.name): \(variantName)")
        return variantName == "variation"
    }
}

private enum UnleashError: CustomNSError {
    case requestTookTooLong(TimeInterval)
    case requestFailed(NSError)
}

struct AlwaysControlABTester: ABTester {

    func prepare() {}
    func disable() {}

    func isVariationActivated(for test: ABTest?) -> Bool {
        false
    }
}

extension UnleashClient: UnleashClientWrapper {

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

    func variantName(forTestName testName: String) -> String? {
        isEnabled(name: testName) ? getVariant(name: testName).name : nil
    }
}
