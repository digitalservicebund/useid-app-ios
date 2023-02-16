import XCTest
import ComposableArchitecture
import TCACoordinators
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

class IdentificationCANCoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockIDInteractionManager: MockIDInteractionManagerType!
    var mockStorageManager: MockStorageManagerType!
    var mockAnalyticsClient: MockAnalyticsClient!
    var openedURL: URL?
    var urlOpener: ((URL) -> Void)!
    
    override func setUp() {
        mockIDInteractionManager = MockIDInteractionManagerType()
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
    }
    
    override func tearDown() {
        openedURL = nil
    }
    
    func testCANIntroFromImmediateThirdAttemptToCanScan() throws {
        let pin = "123456"
        let can = "123456"
        let request = EIDAuthenticationRequest.preview
        let pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: { _, _ in })
        let newPINCANCallback = PINCANCallback(id: UUID(number: 1), callback: { _, _ in })
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             request: request,
                                                             pinCANCallback: pinCANCallback,
                                                             tokenURL: demoTokenURL,
                                                             attempt: 0,
                                                             states: [
                                                                 .root(.canIntro(CANIntro.State(isRootOfCANFlow: true)))
                                                             ]),
            reducer: IdentificationCANCoordinator()
        )
        
        store.send(.routeAction(0, action: .canIntro(.showInput(isRootOfCANFlow: true)))) {
            $0.routes.append(.push(.canInput(CANInput.State(pushesToPINEntry: false))))
        }
        
        store.send(.routeAction(1, action: .canInput(.done(can: can, pushesToPINEntry: false)))) {
            $0.can = can
            $0.routes.append(.push(
                .canScan(IdentificationCANScan.State(pin: pin,
                                                     can: can,
                                                     pinCANCallback: $0.pinCANCallback,
                                                     shared: SharedScan.State(showInstructions: false)))))
        }
        
        store.send(.routeAction(2, action: .canScan(.requestPINAndCAN(newPINCANCallback)))) {
            $0.pinCANCallback = newPINCANCallback
            $0.routes.append(.sheet(.canIncorrectInput(.init())))
        }
    }
    
    func testCanScanWrongCANToScan() throws {
        let pin = "123456"
        let can = "123456"
        let enteredCan = "654321"
        let request = EIDAuthenticationRequest.preview
        let pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: { _, _ in })
        let newPINCANCallback = PINCANCallback(id: UUID(number: 1), callback: { _, _ in })
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             request: request,
                                                             pinCANCallback: pinCANCallback,
                                                             tokenURL: demoTokenURL,
                                                             attempt: 0,
                                                             states: [
                                                                 .root(.canScan(.init(pin: pin,
                                                                                      can: can,
                                                                                      pinCANCallback: pinCANCallback)))
                                                             ]),
            reducer: IdentificationCANCoordinator()
        )
        
        store.send(.routeAction(0, action: .canScan(.requestPINAndCAN(newPINCANCallback)))) {
            $0.pinCANCallback = newPINCANCallback
            $0.routes.append(.sheet(.canIncorrectInput(.init())))
        }
        
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
        let request = EIDAuthenticationRequest.preview
        let pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: { _, _ in })
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             request: request,
                                                             pinCANCallback: pinCANCallback,
                                                             tokenURL: demoTokenURL,
                                                             attempt: 0,
                                                             states: [
                                                                 .root(.canScan(.init(pin: pin,
                                                                                      can: can,
                                                                                      pinCANCallback: pinCANCallback)))
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
        let request = EIDAuthenticationRequest.preview
        let pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: { _, _ in })
        let newPINCANCallback = PINCANCallback(id: UUID(number: 1), callback: { _, _ in })
        
        let oldRoutes: [Route<IdentificationCANScreen.State>] = [
            .root(.canIntro(CANIntro.State(isRootOfCANFlow: true))),
            .push(.canInput(CANInput.State(pushesToPINEntry: false))),
            .push(.canScan(IdentificationCANScan.State(pin: pin, can: can, pinCANCallback: newPINCANCallback, shared: SharedScan.State(showInstructions: false)))),
            .sheet(.canIncorrectInput(CANIncorrectInput.State()))
        ]
        
        let store = TestStore(
            initialState: IdentificationCANCoordinator.State(pin: pin,
                                                             can: can,
                                                             request: request,
                                                             pinCANCallback: pinCANCallback,
                                                             tokenURL: demoTokenURL,
                                                             attempt: 0,
                                                             states: oldRoutes),
            reducer: IdentificationCANCoordinator()
        )
        
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
    
        let routesWithSheetDismissed = Array(oldRoutes.dropLast(1))
    
        let updatedRoutes: [Route<IdentificationCANScreen.State>] = [
            .sheet(.canIntro(CANIntro.State(isRootOfCANFlow: true)))
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
}
