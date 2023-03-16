//
//  ABTesterTests.swift
//  BundesIdentTests
//
//  Created by Daria Kuznetsova on 16.03.23.
//

import XCTest
import Analytics
import Cuckoo
import Sentry
@testable import BundesIdent

final class ABTesterTests: XCTestCase {

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

        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)

        verify(mockUnleashClient).context.set(any())
        XCTAssert(context["supportedToggles"]?.contains(ABTest.test.name) == false)
        XCTAssertEqual(context["someKey"], "someValue")
        XCTAssertNil(context["someOtherKey"])
        XCTAssertEqual(sut.state, .initial)
    }

    func testPrepareSetsStateToLoadingAndCallsStartOnClient() async {
        let expectation = XCTestExpectation(description: "unleash client responds with success")
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
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
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.start().thenDoNothing()
        }

        await sut.prepare()

        XCTAssertEqual(sut.state, .active)
    }

    func testPrepareWhenClientSucceedsInDisabledStateCapturesError() async {
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.start().then {
                sut.disable()
            }
        }

        await sut.prepare()

        verify(mockIssueTracker).capture(error: any())
    }

    func testPrepareWhenClientThrowsSetsStateToDisabledAndCapturesError() async {
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.start().thenThrow(TestError())
        }

        await sut.prepare()

        XCTAssertEqual(sut.state, .disabled)
        verify(mockIssueTracker).capture(error: any())
    }

    func testDisableChangesStateToDisabled() async {
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)

        sut.disable()

        XCTAssertEqual(sut.state, .disabled)
    }

    func testIsVariationActivatedWhenClientReturnsVariationTracksVariationAndReturnsTrue() async {
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.variantName(forTestName: "test").thenReturn("variation")
        }
        await sut.prepare()

        let result = sut.isVariationActivated(for: .test)

        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "abtesting", action: "test", name: "variation"))
        verify(mockIssueTracker).addBreadcrumb(crumb: any())
        XCTAssertTrue(result)
    }

    func testIsVariationActivatedWhenClientReturnsOriginalTracksOriginalAndReturnsFalse() async {
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        stub(mockUnleashClient) {
            $0.variantName(forTestName: "test").thenReturn("original")
        }
        await sut.prepare()

        let result = sut.isVariationActivated(for: .test)

        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "abtesting", action: "test", name: "original"))
        verify(mockIssueTracker).addBreadcrumb(crumb: any())
        XCTAssertFalse(result)
    }

    func testIsVariationActivatedInDisabledStateReturnsFalseEarly() {
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        sut.disable()

        XCTAssertFalse(sut.isVariationActivated(for: .test))
        verify(mockAnalyticsClient, times(0)).track(event: any())
        verify(mockIssueTracker, times(0)).addBreadcrumb(crumb: any())
    }

    func testIsVariationActivatedForNilReturnsFalseEarly() async {
        let sut = Unleash(unleash: mockUnleashClient, analytics: mockAnalyticsClient, issueTracker: mockIssueTracker)
        await sut.prepare()

        let result = sut.isVariationActivated(for: nil)

        verify(mockAnalyticsClient, times(0)).track(event: any())
        verify(mockIssueTracker, times(0)).addBreadcrumb(crumb: any())
        XCTAssertFalse(result)
    }
}

private struct TestError: Error {}
