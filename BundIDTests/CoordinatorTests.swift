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
    var mockStorageManager = MockStorageManagerType()
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        scheduler = DispatchQueue.test
        environment = AppEnvironment.mocked(uuidFactory: uuidFactory,
                                            idInteractionManager: mockIDInteractionManager,
                                            storageManager: mockStorageManager)
    }
    
    func testOpeningTheAppWithUnfinishedSetup() {
        let store = TestStore(initialState: CoordinatorState(states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(false)
        }
        
        store.send(.onAppear) {
            $0.states.append(.sheet(.setupCoordinator(SetupCoordinatorState(tokenURL: nil)), embedInNavigationView: false))
        }
    }

    func testOpenEIDURLWithUnfinishedSetup() {
        let store = TestStore(initialState: CoordinatorState(states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(false)
        }
        
        let tokenURLString = "eid://example.org"
        store.send(.openURL(URL(string: tokenURLString)!)) {
            guard case .home(var homeState) = $0.states[0].screen else { return XCTFail("Incorrect state") }
            homeState.tokenURL = tokenURLString
            $0.tokenURL = tokenURLString
            $0.states = [.root(.home(homeState)), .sheet(.setupCoordinator(SetupCoordinatorState(tokenURL: tokenURLString)), embedInNavigationView: false)]
        }
    }
    
    func testOpenEIDURLWithFinishedSetup() {
        let store = TestStore(initialState: CoordinatorState(states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.setupCompleted.get.thenReturn(true)
        }
        
        let tokenURLString = "eid://example.org"
        store.send(.openURL(URL(string: tokenURLString)!)) {
            guard case .home(var homeState) = $0.states[0].screen else { return XCTFail("Incorrect state") }
            homeState.tokenURL = tokenURLString
            $0.tokenURL = tokenURLString
            $0.states = [.root(.home(homeState)), .sheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURLString)), embedInNavigationView: false)]
        }
    }
    
    func testOpenOtherURL() {
        let store = TestStore(initialState: CoordinatorState(states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1)))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.openURL(URL(string: "https://example.org")!))
        
    }
    
    func testAbortSetup() {
        let store = TestStore(initialState: CoordinatorState(states: [.root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1))),
                                                                      .sheet(.setupCoordinator(SetupCoordinatorState()))]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseSetupAlreadyDone))))) {
            $0.states.removeLast()
        }
    }

    func testAbortSetupWithTokenURL() {
        let tokenURL = "eid://example.org"
        let store = TestStore(initialState: CoordinatorState(tokenURL: tokenURL,
                                                             states: [
                                                                .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1, tokenURL: tokenURL))),
                                                                .sheet(.setupCoordinator(SetupCoordinatorState()))
                                                             ]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseSetupAlreadyDone)))))
        
        let newRoutes: [Route<ScreenState>] = [
            .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1, tokenURL: tokenURL))),
            .sheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)))
        ]
        
        store.receive(.updateRoutes(newRoutes)) {
            $0.states = newRoutes
        }
    }
    
    func testRememberSetupWasFinishedAfterScanningSuccessfully() {
        let tokenURL = "eid://example.org"
        
        var setupCoordinatorState = SetupCoordinatorState(transportPIN: "12345",
                                                          states: [
                                                            .root(.intro),
                                                            .push(.scan(.init(transportPIN: "12345", newPIN: "123456")))
                                                          ])
        let store = TestStore(initialState: CoordinatorState(tokenURL: tokenURL,
                                                             states: [
                                                                .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1, tokenURL: tokenURL))),
                                                                .sheet(.setupCoordinator(setupCoordinatorState)),
                                                             ]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.updateSetupCompleted(any()).thenDoNothing()
        }
        
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(1, action: .scan(.scannedSuccessfully))))) {
            setupCoordinatorState.states.push(.done(SetupDoneState()))
            $0.states[1] = .sheet(.setupCoordinator(setupCoordinatorState))
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
        
        let store = TestStore(initialState: CoordinatorState(tokenURL: tokenURL,
                                                             states: [
                                                                .root(.home(HomeState(appVersion: "1.0.0", buildNumber: 1, tokenURL: tokenURL))),
                                                                .sheet(.identificationCoordinator(identificationCoordinatorState)),
                                                             ]),
                              reducer: coordinatorReducer,
                              environment: environment)
        
        stub(mockStorageManager) {
            $0.updateSetupCompleted(any()).thenDoNothing()
        }
        
        let redirectURL = "https://example.org"
        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(0, action: .scan(.identifiedSuccessfullyWithRedirect(.preview, redirectURL: redirectURL)))))) {
            identificationCoordinatorState.states.push(.done(IdentificationDoneState(request: .preview, redirectURL: redirectURL)))
            $0.states[1] = .sheet(.identificationCoordinator(identificationCoordinatorState))
        }
        
        verify(mockStorageManager).updateSetupCompleted(true)
    }
}
