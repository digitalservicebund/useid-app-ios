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
    var environment: AppEnvironment!
    var uuidCount = 0
    
    var mockIDInteractionManager = MockIDInteractionManagerType()
    var mockStorageManager = MockStorageManagerType()
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        mockIssueTracker = MockIssueTracker()
        environment = AppEnvironment.mocked(uuidFactory: uuidFactory,
                                            idInteractionManager: mockIDInteractionManager,
                                            storageManager: mockStorageManager,
                                            analytics: mockAnalyticsClient,
                                            issueTracker: mockIssueTracker)
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
        
        stub(mockIssueTracker) {
            $0.addBreadcrumb(crumb: any()).thenDoNothing()
            $0.capture(error: any()).thenDoNothing()
        }
    }
    
    func testOpeningTheAppWithUnfinishedSetup() {
        
        let store = TestStore(initialState: CoordinatorState(routes: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(false)
        }
        
        store.send(.onAppear) {
            $0.routes.append(.sheet(.setupCoordinator(SetupCoordinatorState(tokenURL: nil)), embedInNavigationView: false))
        }
    }
    
    func testOpenEIDURLWithUnfinishedSetup() {
        let home = Route.root(ScreenState.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: CoordinatorState(routes: [home]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(false)
        }
        
        let tokenURLString = URL(string: "eid://example.org")!
        store.send(.openURL(tokenURLString)) {
            $0.routes = [home, .sheet(.setupCoordinator(SetupCoordinatorState(tokenURL: tokenURLString)), embedInNavigationView: false)]
        }
    }
    
    func testOpenEIDURLWithFinishedSetup() {
        let home = Route.root(ScreenState.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: CoordinatorState(routes: [home]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(true)
        }
        
        let tokenURLString = URL(string: "eid://example.org")!
        store.send(.openURL(tokenURLString)) {
            $0.routes = [home, .sheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURLString)), embedInNavigationView: false)]
        }
    }
    
    func testAbortSetup() {
        let store = TestStore(initialState: CoordinatorState(routes: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1))),
                                                                      .sheet(.setupCoordinator(SetupCoordinatorState()))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseSkipSetup(tokenURL: nil)))))) {
            $0.routes.removeLast()
        }
    }
    
    func testAbortSetupWithTokenURL() {
        let tokenURL = URL(string: "eid://example.org")!
        let store = TestStore(initialState: CoordinatorState(routes: [
            .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1))),
            .sheet(.setupCoordinator(SetupCoordinatorState()))
        ]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseSkipSetup(tokenURL: tokenURL))))))
        
        let newRoutes: [Route<ScreenState>] = [
            .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1))),
            .sheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)))
        ]
        
        store.receive(.updateRoutes(newRoutes)) {
            $0.routes = newRoutes
        }
    }
    
    func testTriggerSetup() {
        let root = Route<ScreenState>.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: CoordinatorState(routes: [root]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(0, action: .home(.triggerSetup))) { state in
            state.routes = [root, .sheet(.setupCoordinator(SetupCoordinatorState()))]
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "buttonPressed",
                                                                name: "start"))
    }
}
