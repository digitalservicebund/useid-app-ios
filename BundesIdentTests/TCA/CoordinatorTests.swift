import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators
import Analytics

@testable import BundesIdent

final class CoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockIssueTracker: MockIssueTracker!
    var mockIDInteractionManager = MockIDInteractionManagerType()
    var mockStorageManager = MockStorageManagerType()
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        mockIssueTracker = MockIssueTracker()
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
        
        stub(mockIssueTracker) {
            $0.addBreadcrumb(crumb: any()).thenDoNothing()
            $0.capture(error: any()).thenDoNothing()
        }
    }
    
    func testExtractingTCTokenURLFromUniversalLink() {
        let url = URL(string: "https://eid.digitalservicebund.de/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token&hash=fd143658f7b864701f56deb9fb134882010019a1797ef8019e406da8d875ae18")!
        let coordinator = Coordinator()
        let tcTokenURL = coordinator.extractTCTokenURL(url: url)
        let expectedURL = URL(string: "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token")!
        XCTAssertEqual(tcTokenURL, expectedURL)
    }
    
    func testExtractingTCTokenURLFromBundesIdentScheme() {
        let url = URL(string: "bundesident://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token")!
        let coordinator = Coordinator()
        let tcTokenURL = coordinator.extractTCTokenURL(url: url)
        let expectedURL = URL(string: "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token")!
        XCTAssertEqual(tcTokenURL, expectedURL)
    }
    
    func testOpeningTheAppWithUnfinishedSetup() {
        let store = TestStore(initialState: Coordinator.State(routes: [.root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: Coordinator())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.storageManager = mockStorageManager
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(false)
        }
        
        store.send(.onAppear)
    }
    
    func testOpenEIDURLWithUnfinishedSetup() {
        let home = Route.root(Screen.State.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: Coordinator.State(routes: [home]),
                              reducer: Coordinator())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.storageManager = mockStorageManager
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(false)
        }
        
        let tokenURLString = URL(string: "bundesident://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token")!
        let encodedTCTokenURL = URL(string: "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token")!
        store.send(.openURL(tokenURLString)) {
            $0.routes = [home, .sheet(.setupCoordinator(SetupCoordinator.State(tokenURL: encodedTCTokenURL)), embedInNavigationView: false)]
        }
    }
    
    func testOpenEIDURLWithFinishedSetup() {
        let home = Route.root(Screen.State.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: Coordinator.State(routes: [home]),
                              reducer: Coordinator())
        store.dependencies.storageManager = mockStorageManager
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(true)
        }
        
        let tokenURLString = URL(string: "bundesident://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token")!
        let encodedTCTokenURL = URL(string: "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Feid.digitalservicebund.de%2Fapi%2Fv1%2Fidentification%2Fsessions%2F57a2537b-87c3-4170-83fb-3fbb9a245888%2Ftc-token")!
        store.send(.openURL(tokenURLString)) {
            $0.routes = [home, .sheet(.identificationCoordinator(IdentificationCoordinator.State(tokenURL: encodedTCTokenURL)), embedInNavigationView: false)]
        }
    }
    
    func testAbortSetup() {
        let store = TestStore(initialState: Coordinator.State(routes: [
            .root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1))),
            .sheet(.setupCoordinator(SetupCoordinator.State()))
        ]),
        reducer: Coordinator())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseSkipSetup(tokenURL: nil)))))) {
            $0.routes.removeLast()
        }
    }
    
    func testAbortSetupWithTokenURL() {
        let tokenURL = URL(string: "bundesident://example.org")!
        let store = TestStore(initialState: Coordinator.State(routes: [
            .root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1))),
            .sheet(.setupCoordinator(SetupCoordinator.State()))
        ]),
        reducer: Coordinator())
        
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseSkipSetup(tokenURL: tokenURL))))))
        
        let newRoutes: [Route<Screen.State>] = [
            .root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1))),
            .sheet(.identificationCoordinator(IdentificationCoordinator.State(tokenURL: tokenURL, canGoBackToSetupIntro: true)))
        ]
        
        store.receive(.updateRoutes(newRoutes)) {
            $0.routes = newRoutes
        }
    }
    
    func testTriggerSetup() {
        let root = Route<Screen.State>.root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: Coordinator.State(routes: [root]),
                              reducer: Coordinator())
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.send(.routeAction(0, action: .home(.triggerSetup))) { state in
            state.routes = [root, .sheet(.setupCoordinator(SetupCoordinator.State()))]
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "buttonPressed",
                                                                name: "start"))
    }
}
