import XCTest
import MatomoTracker
@testable import Analytics

final class MatomoAnalyticsClientTests: XCTestCase {
    private var mock: MockMatomoTracker!
    private var matomoAnalyticsClient: MatomoAnalyticsClient!
    
    override func setUp() async throws {
        mock = MockMatomoTracker()
        matomoAnalyticsClient = MatomoAnalyticsClient(tracker: mock)
    }
    
    override func tearDown() async throws {
        matomoAnalyticsClient = nil
        mock = nil
    }
    
    func testResetsOnFirstEvent() {
        XCTAssertEqual(mock.resetCount, 0)
        matomoAnalyticsClient.track(event: .fake)
        XCTAssertEqual(mock.resetCount, 1)
    }
    
    func testResetsOnFirstView() {
        XCTAssertEqual(mock.resetCount, 0)
        matomoAnalyticsClient.track(view: FakeAnalyticsView())
        XCTAssertEqual(mock.resetCount, 1)
    }
    
    func testResetsAfterSessionTimeout() {
        matomoAnalyticsClient = MatomoAnalyticsClient(tracker: mock, sessionTimeout: 1)
        
        matomoAnalyticsClient.track(event: .fake)
        Thread.sleep(forTimeInterval: 1)
        matomoAnalyticsClient.track(event: .fake)
        XCTAssertEqual(mock.resetCount, 2)
    }
    
    func testTrackingWithinSingleSession() {
        matomoAnalyticsClient.track(view: FakeAnalyticsView())
        matomoAnalyticsClient.track(event: .fake)
        matomoAnalyticsClient.track(event: .fake)
        XCTAssertEqual(mock.resetCount, 1)
    }
    
    func testEventTracking() {
        let event = AnalyticsEvent(category: "category", action: "action", name: "name", value: 100)
        matomoAnalyticsClient.track(event: event)
       
        XCTAssertEqual(mock.trackedEvents.count, 1)
        XCTAssertEqual(mock.trackedEvents.first?.category, event.category)
        XCTAssertEqual(mock.trackedEvents.first?.action, event.action)
        XCTAssertEqual(mock.trackedEvents.first?.name, event.name)
        XCTAssertEqual(mock.trackedEvents.first?.value, event.value)
    }
    
    func testViewTracking() {
        let view = FakeAnalyticsView(route: ["a", "b", "b"])
        matomoAnalyticsClient.track(view: view)
        
        XCTAssertEqual(mock.trackedViews.count, 1)
        XCTAssertEqual(mock.trackedViews.first, view.route)
    }
    
    func testRepeatedViewTracking() {
        let view = FakeAnalyticsView()
        matomoAnalyticsClient.track(view: view)
        matomoAnalyticsClient.track(view: view)
        
        XCTAssertEqual(mock.trackedViews.count, 1)
        XCTAssertEqual(mock.trackedViews.first, view.route)
    }
    
    func testDispatch() {
        matomoAnalyticsClient.dispatch()
        XCTAssertEqual(mock.dispatchCount, 1)
    }
}
