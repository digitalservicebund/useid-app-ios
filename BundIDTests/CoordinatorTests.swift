import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundID

final class CoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    var uuidCount = 0
    
    var mockIDInteractionManager = MockIDInteractionManagerType()
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        scheduler = DispatchQueue.test
        environment = AppEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                     uuidFactory: uuidFactory,
                                     idInteractionManager: mockIDInteractionManager,
                                     debugIDInteractionManager: DebugIDInteractionManager())
    }

    func testOpenEIDURLWithUnfinishedSetup() {
        let store = TestStore(initialState: CoordinatorState(setupPreviouslyFinished: false,
                                                             states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        let tokenURLString = "eid://example.org"
        store.send(.openURL(URL(string: tokenURLString)!)) {
            guard case .home(var homeState) = $0.states[0].screen else { return XCTFail("Incorrect state") }
            homeState.tokenURL = tokenURLString
            $0.tokenURL = tokenURLString
            $0.states = [.root(.home(homeState)), .sheet(.setupCoordinator(SetupCoordinatorState(tokenURL: tokenURLString)), embedInNavigationView: false)]
        }
    }
    
    func testOpenEIDURLWithFinishedSetup() {
        let store = TestStore(initialState: CoordinatorState(setupPreviouslyFinished: true,
                                                             states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        let tokenURLString = "eid://example.org"
        store.send(.openURL(URL(string: tokenURLString)!)) {
            guard case .home(var homeState) = $0.states[0].screen else { return XCTFail("Incorrect state") }
            homeState.tokenURL = tokenURLString
            $0.tokenURL = tokenURLString
            $0.states = [.root(.home(homeState)), .sheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURLString)), embedInNavigationView: true)]
        }
    }
    
    func testOpenOtherURL() {
        let store = TestStore(initialState: CoordinatorState(setupPreviouslyFinished: false,
                                                             states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.openURL(URL(string: "https://example.org")!))
        
    }
    
    func testAbortSetup() {
        let store = TestStore(initialState: CoordinatorState(setupPreviouslyFinished: false,
                                                             states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1))),
                                                                      .sheet(.setupCoordinator(SetupCoordinatorState()))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseYes))))) {
            $0.states.removeLast()
        }
    }

    func testAbortSetupWithTokenURL() {
        let tokenURL = "eid://example.org"
        let store = TestStore(initialState: CoordinatorState(tokenURL: tokenURL,
                                                             setupPreviouslyFinished: false,
                                                             states: [
                                                                .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1, tokenURL: tokenURL))),
                                                                .sheet(.setupCoordinator(SetupCoordinatorState()))
                                                             ]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseYes)))))
        
        let newRoutes: [Route<ScreenState>] = [
            .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1, tokenURL: tokenURL))),
            .sheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)))
        ]
        
        store.receive(.updateRoutes(newRoutes)) {
            $0.states = newRoutes
        }
    }
}
