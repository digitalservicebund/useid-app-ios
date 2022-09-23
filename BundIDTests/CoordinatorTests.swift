import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators
import Analytics

@testable import BundID

final class CoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
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
        environment = AppEnvironment.mocked(uuidFactory: uuidFactory,
                                            idInteractionManager: mockIDInteractionManager,
                                            storageManager: mockStorageManager,
                                            analytics: mockAnalyticsClient)
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
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
        
        let tokenURLString = "eid://example.org"
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
        
        let tokenURLString = "eid://example.org"
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
        let tokenURL = "eid://example.org"
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
    
    func testRememberSetupWasFinishedAfterScanningSuccessfully() {
        let tokenURL = "eid://example.org"
        var setupCoordinatorState = SetupCoordinatorState(transportPIN: "12345",
                                                          states: [
                                                            .root(.intro(.init(tokenURL: tokenURL))),
                                                            .push(.scan(.init(transportPIN: "12345", newPIN: "123456")))
                                                          ])
        let store = TestStore(initialState: CoordinatorState(routes: [
            .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1))),
            .sheet(.setupCoordinator(setupCoordinatorState)),
        ]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.updateSetupCompleted(any()).thenDoNothing()
        }
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(1, action: .scan(.scannedSuccessfully))))) {
            setupCoordinatorState.routes.push(.done(SetupDoneState()))
            $0.routes[1] = .sheet(.setupCoordinator(setupCoordinatorState))
        }
        
        verify(mockStorageManager).updateSetupCompleted(true)
    }
    
    func testRememberSetupWasFinishedAfterIdentifyingSuccessfully() {
        let tokenURL = "eid://example.org"
        
        var identificationCoordinatorState = IdentificationCoordinatorState(tokenURL: tokenURL,
                                                                            pin: "123456",
                                                                            states: [
                                                                                .root(.scan(IdentificationScanState(request: .preview,
                                                                                                                    pin: "123456",
                                                                                                                    pinCallback: PINCallback(id: UUID(number: 1),
                                                                                                                                             callback: { _ in }))))
                                                                            ])
        
        let store = TestStore(initialState: CoordinatorState(routes: [
            .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1))),
            .sheet(.identificationCoordinator(identificationCoordinatorState)),
        ]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.updateSetupCompleted(any()).thenDoNothing()
        }
        
        let redirectURL = "https://example.org"
        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(0, action: .scan(.identifiedSuccessfullyWithRedirect(.preview, redirectURL: redirectURL)))))) {
            identificationCoordinatorState.routes.push(.done(IdentificationDoneState(request: .preview, redirectURL: redirectURL)))
            $0.routes[1] = .sheet(.identificationCoordinator(identificationCoordinatorState))
        }
        
        verify(mockStorageManager).updateSetupCompleted(true)
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
