import XCTest
import ComposableArchitecture
import TCACoordinators
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

class IdentificationCANCoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockEIDInteractionManager: MockEIDInteractionManagerType!
    var mockStorageManager: MockStorageManagerType!
    var mockAnalyticsClient: MockAnalyticsClient!
    var openedURL: URL?
    var urlOpener: ((URL) -> Void)!
    
    override func setUp() {
        mockEIDInteractionManager = MockEIDInteractionManagerType()
        mockStorageManager = MockStorageManagerType()
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        urlOpener = { self.openedURL = $0 }
        
        stub(mockStorageManager) {
            when($0.setupCompleted.set(any())).thenDoNothing()
        }
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
        
        stub(mockEIDInteractionManager) {
            $0.interrupt().thenDoNothing()
        }
    }
    
    override func tearDown() {
        openedURL = nil
    }
    
    func testCANIntroFromImmediateThirdAttemptToCanScan() throws {
        let pin = "123456"
        let can = "123456"
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             identificationInformation: .preview,
                                                             attempt: 0,
                                                             states: [
                                                                 .root(.canIntro(CANIntro.State(shouldDismiss: true)))
                                                             ]),
            reducer: IdentificationCANCoordinator()
        )
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.send(.routeAction(0, action: .canIntro(.showInput(shouldDismiss: true)))) {
            $0.routes.append(.push(.canInput(CANInput.State(pushesToPINEntry: false))))
        }
        
        store.send(.routeAction(1, action: .canInput(.done(can: can, pushesToPINEntry: false)))) {
            $0.can = can
            $0.routes.append(.push(
                .canScan(IdentificationCANScan.State(pin: pin,
                                                     can: can,
                                                     identificationInformation: .preview,
                                                     shared: SharedScan.State(startOnAppear: true)))))
        }
        
        store.send(.routeAction(2, action: .canScan(.scanEvent(.success(.canRequested)))))
        
        store.receive(.routeAction(2, action: .canScan(.wrongCAN))) {
            $0.routes.append(.sheet(.canIncorrectInput(.init())))
        }
        
        verify(mockEIDInteractionManager).interrupt()
    }
    
    func testCanScanWrongCANToScan() throws {
        let pin = "123456"
        let can = "123456"
        let enteredCan = "654321"
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             identificationInformation: .preview,
                                                             attempt: 0,
                                                             states: [
                                                                 .root(.canScan(.init(pin: pin,
                                                                                      can: can,
                                                                                      identificationInformation: .preview)))
                                                             ]),
            reducer: IdentificationCANCoordinator()
        )
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        store.send(.routeAction(0, action: .canScan(.scanEvent(.success(.canRequested)))))
        store.receive(.routeAction(0, action: .canScan(.wrongCAN))) {
            $0.routes.append(.sheet(.canIncorrectInput(.init())))
        }
        
        verify(mockEIDInteractionManager).interrupt()
        
        store.send(.routeAction(1, action: .canIncorrectInput(.done(can: enteredCan)))) {
            guard case .canScan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            $0.attempt += 1
            $0.can = enteredCan
            scanState.shared.attempt = $0.attempt
            scanState.can = $0.can!
            $0.routes = [.root(.canScan(scanState))]
        }
    }

    func testCanScanBlocksCard() throws {
        let pin = "123456"
        let can = "123456"
        let cardBlockedError = ScanError.State(errorType: .cardBlocked, retry: false)
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             identificationInformation: .preview,
                                                             attempt: 0,
                                                             states: [
                                                                 .root(.canScan(.init(pin: pin,
                                                                                      can: can,
                                                                                      identificationInformation: .preview)))
                                                             ]),
            reducer: IdentificationCANCoordinator()
        )
    
        store.send(.routeAction(0, action: .canScan(.error(cardBlockedError)))) {
            $0.routes.append(.sheet(.error(cardBlockedError)))
        }
    }
    
    func testScanFromImmediateThirdAttemptPopsToCanIntro() throws {
        let pin = "123456"
        let can = "123456"
        
        let oldRoutes: [Route<IdentificationCANScreen.State>] = [
            .root(.canIntro(CANIntro.State(shouldDismiss: true))),
            .push(.canInput(CANInput.State(pushesToPINEntry: false))),
            .push(.canScan(IdentificationCANScan.State(pin: pin,
                                                       can: can,
                                                       identificationInformation: .preview,
                                                       shared: SharedScan.State(startOnAppear: true)))),
            .sheet(.canIncorrectInput(CANIncorrectInput.State()))
        ]
        
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             identificationInformation: .preview,
                                                             attempt: 0,
                                                             states: oldRoutes),
            reducer: IdentificationCANCoordinator()
        )
        
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
    
        let routesWithSheetDismissed = Array(oldRoutes.dropLast(1))
    
        let updatedRoutes: [Route<IdentificationCANScreen.State>] = [
            .sheet(.canIntro(CANIntro.State(shouldDismiss: true)))
        ]
        
        store.send(.routeAction(3, action: .canIncorrectInput(.end)))
        store.receive(.updateRoutes(oldRoutes))
        store.receive(.updateRoutes(routesWithSheetDismissed)) {
            $0.routes = routesWithSheetDismissed
        }
        
        scheduler.advance(by: .seconds(0.65))
        
        store.receive(.updateRoutes(updatedRoutes)) {
            $0.routes = updatedRoutes
        }
    }
    
    func testCancellationAndRestartingFlow() throws {
        let pin = "123456"
        let can = "123456"
        
        let oldRoutes: [Route<IdentificationCANScreen.State>] = [
            .root(.canScan(IdentificationCANScan.State(pin: pin,
                                                       can: can,
                                                       identificationInformation: .preview,
                                                       shared: SharedScan.State(startOnAppear: true))))
        ]
        
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             identificationInformation: .preview,
                                                             attempt: 0,
                                                             states: oldRoutes),
            reducer: IdentificationCANCoordinator()
        )
        
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        
        store.send(.routeAction(0, action: .canScan(.scanEvent(.success(.identificationCancelled))))) {
            guard case .canScan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            scanState.shouldRestartAfterCancellation = true
            $0.routes[0].screen = .canScan(scanState)
        }
        
        store.send(.routeAction(0, action: .canScan(.shared(.startScan(userInitiated: true))))) {
            guard case .canScan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            scanState.shouldRestartAfterCancellation = false
            scanState.shared.scanAvailable = false
            $0.routes[0].screen = .canScan(scanState)
        }
        
        store.receive(.routeAction(0, action: .canScan(.identify)))
        
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        stub(mockEIDInteractionManager) {
            $0.setCAN(any()).thenDoNothing()
        }
        
        store.send(.routeAction(0, action: .canScan(.scanEvent(.success(.identificationStarted))))) {
            guard case .canScan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            scanState.shouldProvideCAN = true
            $0.routes[0].screen = .canScan(scanState)
        }
        
        store.send(.routeAction(0, action: .canScan(.scanEvent(.success(.canRequested))))) {
            guard case .canScan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            scanState.shouldProvideCAN = false
            $0.routes[0].screen = .canScan(scanState)
        }
        
        verify(mockEIDInteractionManager).setCAN(can)
    }
}
