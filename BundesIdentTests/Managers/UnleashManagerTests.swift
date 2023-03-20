import XCTest
import Analytics
import Cuckoo
import Sentry
@testable import BundesIdent

final class UnleashManagerTests: XCTestCase {

    var mockUnleashClient: MockUnleashClientWrapper!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockIssueTracker: MockIssueTracker!

    override func setUp() {
        mockUnleashClient = MockUnleashClientWrapper()
        mockAnalyticsClient = MockAnalyticsClient()
        mockIssueTracker = MockIssueTracker()

        stub(mockUnleashClient) {
            $0.context.get.thenReturn([:])
            $0.context.set(any()).thenDoNothing()
            $0.start().thenDoNothing()
        }
        stub(mockIssueTracker) {
            $0.addBreadcrumb(crumb: any()).thenDoNothing()
            $0.capture(error: any()).thenDoNothing()
        }
        stub(mockAnalyticsClient) {
            $0.track(event: any()).thenDoNothing()
        }
    }

    func testInitSetsSupportedToggles() {
        var context = ["someKey": "someValue"]
        stub(mockUnleashClient) {
            $0.context.get.thenReturn(context)
            $0.context.set(any()).then {
                context = $0
            }
        }

        let uuid = { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker, uuid: uuid)

        verify(mockUnleashClient).context.set(any())
        XCTAssertEqual(context.count, 4)
        XCTAssertEqual(context["someKey"], "someValue")
        XCTAssert(context["supportedToggles"]?.contains(ABTest.test.name) == false)
        XCTAssertEqual(context["appName"], "bundesIdent.iOS")
        XCTAssertEqual(context["sessionId"], "00000000-0000-0000-0000-000000000000")
        XCTAssertNil(context["someOtherKey"])
        XCTAssertEqual(sut.state, .initial)
    }

    func testPrepareSetsStateToLoadingAndCallsStartOnClient() async {
        let expectation = XCTestExpectation(description: "unleash client responds with success")
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.start().then {
                guard sut.state == .loading else { return }
                expectation.fulfill()
            }
        }

        await sut.prepare()

        wait(for: [expectation], timeout: 0.0)
    }

    func testPrepareWhenClientSucceedsSetsStateToActive() async {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.start().thenDoNothing()
        }

        await sut.prepare()

        XCTAssertEqual(sut.state, .active)
    }

    func testPrepareWhenClientSucceedsInDisabledStateCapturesError() async {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.start().then {
                sut.disable()
            }
        }

        await sut.prepare()

        verify(mockIssueTracker).capture(error: any())
    }

    func testPrepareWhenClientThrowsSetsStateToDisabledAndCapturesError() async {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.start().thenThrow(TestError())
        }

        await sut.prepare()

        XCTAssertEqual(sut.state, .disabled)
        verify(mockIssueTracker).capture(error: any())
    }

    func testDisableChangesStateToDisabled() async {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)

        sut.disable()

        XCTAssertEqual(sut.state, .disabled)
    }

    func testIsVariationActivatedWhenClientReturnsVariationTracksVariationAndReturnsTrue() async {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.variantName(forTestName: "bundesIdent.test").thenReturn("variation")
        }
        await sut.prepare()

        let result = sut.isVariationActivated(for: .test)

        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "abtesting", action: "bundesIdent_test", name: "variation"))
        verify(mockIssueTracker).addBreadcrumb(crumb: any())
        XCTAssertTrue(result)
    }

    func testIsVariationActivatedWhenClientReturnsOriginalTracksOriginalAndReturnsFalse() async {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.variantName(forTestName: "bundesIdent.test").thenReturn("original")
        }
        await sut.prepare()

        let result = sut.isVariationActivated(for: .test)

        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "abtesting", action: "bundesIdent_test", name: "original"))
        verify(mockIssueTracker).addBreadcrumb(crumb: any())
        XCTAssertFalse(result)
    }

    func testIsVariationActivatedInDisabledStateReturnsFalseEarly() {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        sut.disable()

        XCTAssertFalse(sut.isVariationActivated(for: .test))
        verify(mockAnalyticsClient, times(0)).track(event: any())
        verify(mockIssueTracker, times(0)).addBreadcrumb(crumb: any())
    }

    func testIsVariationActivatedForNilReturnsFalseEarly() async {
        let sut = UnleashManager(unleashClient: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        await sut.prepare()

        let result = sut.isVariationActivated(for: nil)

        verify(mockAnalyticsClient, times(0)).track(event: any())
        verify(mockIssueTracker, times(0)).addBreadcrumb(crumb: any())
        XCTAssertFalse(result)
    }
}

private struct TestError: Error {}
