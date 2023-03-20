import Foundation
import Analytics
import UnleashProxyClientSwift

enum ABTest: CaseIterable {
#if PREVIEW
    case test
#endif
    case setupIntroductionExplanation

    var name: String {
        switch self {
#if PREVIEW
        case .test: return "bundesIdent.test"
#endif
        case .setupIntroductionExplanation: return "bundesIdent.setup_introduction_explanation"
        }
    }
}

final class UnleashManager: ABTester {

    convenience init(url: String, clientKey: String, analytics: AnalyticsClient, issueTracker: IssueTracker) {
        let unleashClient = UnleashClient(unleashUrl: url, clientKey: clientKey, refreshInterval: .max)
        self.init(unleashClient: unleashClient, analytics: analytics, issueTracker: issueTracker)
    }

    init(unleashClient: UnleashClientWrapper, analytics: AnalyticsClient, issueTracker: IssueTracker, uuid: () -> UUID = UUID.init) {
        self.unleashClient = unleashClient
        self.analytics = analytics
        self.issueTracker = issueTracker

        var context = unleashClient.context
        context["appName"] = "bundesIdent.iOS"
        context["sessionId"] = uuid().uuidString
        context["supportedToggles"] = ABTest.allCases
#if PREVIEW
            .filter { $0 != .test }
#endif
            .map(\.name)
            .joined(separator: ",")
        unleashClient.context = context
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
                issueTracker.capture(error: UnleashError.requestTookTooLong(Date().timeIntervalSince(start)))
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
        guard state == .active, let test, let variantName = unleashClient.variantName(forTestName: test.name)
        else { return false }

        let matomoTestName = test.name.replacingOccurrences(of: ".", with: "_")
        analytics.track(event: .init(category: "abtesting", action: matomoTestName, name: variantName))
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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            start { error in
                if let error {
                    continuation.resume(throwing: error)
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
