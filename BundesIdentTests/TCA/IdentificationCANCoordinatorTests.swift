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
                                                             pinCANCallback: pinCANCallback,
                                                             tokenURL: demoTokenURL,
                                                             attempt: 0,
                                                             states: [
                                                                .root(.canIntro(IdentificationCANIntro.State(request: request,
                                                                                                             shouldDismiss: true)))
                                                             ]),
            reducer: IdentificationCANCoordinator())
        
        store.send(.routeAction(0, action: .canIntro(.showInput(request, true)))) {
            $0.routes.append(.push(.canInput(IdentificationCANInput.State(request: request, pushesToPINEntry: false))))
        }
        
        store.send(.routeAction(1, action: .canInput(.done(can: can, request: request, pushesToPINEntry: false)))) {
            $0.can = can
            $0.routes.append(.push(
                .canScan(IdentificationCANScan.State(request: request,
                                                     pin: pin,
                                                     can: can,
                                                     pinCANCallback: $0.pinCANCallback,
                                                     shared: SharedScan.State(showInstructions: false)))))
        }
        
        store.send(.routeAction(2, action: .canScan(.requestPINAndCAN(request, newPINCANCallback)))) {
            $0.pinCANCallback = newPINCANCallback
            $0.routes.append(.sheet(.canIncorrectInput(.init(request: request))))
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
                                                             pinCANCallback: pinCANCallback,
                                                             tokenURL: demoTokenURL,
                                                             attempt: 0,
                                                             states: [
                                                                .root(.canScan(.init(request: request,
                                                                                     pin: pin,
                                                                                     can: can,
                                                                                     pinCANCallback: pinCANCallback)))
                                                             ]),
            reducer: IdentificationCANCoordinator())
        
        store.send(.routeAction(0, action: .canScan(.requestPINAndCAN(request, newPINCANCallback)))) {
            $0.pinCANCallback = newPINCANCallback
            $0.routes.append(.sheet(.canIncorrectInput(.init(request: request))))
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
                                                                 pinCANCallback: pinCANCallback,
                                                                 tokenURL: demoTokenURL,
                                                                 attempt: 0,
                                                             states: [
                                                                .root(.canScan(.init(request: request,
                                                                                     pin: pin,
                                                                                     can: can,
                                                                                     pinCANCallback: pinCANCallback)))
                                                             ]),
                reducer: IdentificationCANCoordinator())
    
            store.send(.routeAction(0, action: .canScan(.error(cardBlockedError)))) {
                $0.routes.append(.sheet(.error(cardBlockedError)))
            }
        }
    
        @MainActor
        func testScanFromImmediateThirdAttemptPopsToCanIntro() async throws {
            let pin = "123456"
            let can = "123456"
            let request = EIDAuthenticationRequest.preview
            let pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: { _, _ in })
            let newPINCANCallback = PINCANCallback(id: UUID(number: 1), callback: { _, _ in })
            let store = TestStore(
                initialState: IdentificationCANCoordinator.State(pin: pin,
                                                                 can: can,
                                                                 pinCANCallback: pinCANCallback,
                                                                 tokenURL: demoTokenURL,
                                                                 attempt: 0,
                                                             states: [
                                                                .root(.canIntro(IdentificationCANIntro.State(request: request, shouldDismiss: true))),
                                                                .push(.canInput(IdentificationCANInput.State(request: request, pushesToPINEntry: false))),
                                                                .push(.canScan(IdentificationCANScan.State(request: request, pin: pin, can: can, pinCANCallback: newPINCANCallback, shared: SharedScan.State(showInstructions: false)))),
                                                                .sheet(.canIncorrectInput(IdentificationCANIncorrectInput.State(request: request)))
                                                             ]),
                reducer: IdentificationCANCoordinator())
    
            let oldRoutes: [Route<IdentificationCANScreen.State>] = [
                .root(.canIntro(IdentificationCANIntro.State(request: request, shouldDismiss: true))),
                .push(.canInput(IdentificationCANInput.State(request: request, pushesToPINEntry: false))),
                .push(.canScan(IdentificationCANScan.State(request: request, pin: pin, can: can, pinCANCallback: newPINCANCallback, shared: SharedScan.State(showInstructions: false)))),
                .sheet(.canIncorrectInput(IdentificationCANIncorrectInput.State(request: request)))
            ]
    
            let routesWithSheetDismissed: [Route<IdentificationCANScreen.State>] = [
                .root(.canIntro(IdentificationCANIntro.State(request: request, shouldDismiss: true))),
                .push(.canInput(IdentificationCANInput.State(request: request, pushesToPINEntry: false))),
                .push(.canScan(IdentificationCANScan.State(request: request, pin: pin, can: can, pinCANCallback: newPINCANCallback, shared: SharedScan.State(showInstructions: false))))
            ]
    
            let updatedRoutes: [Route<IdentificationCANScreen.State>] = [
                .root(.canIntro(IdentificationCANIntro.State(request: request, shouldDismiss: true)))
            ]
    
            await store.send(.routeAction(3, action: .canIncorrectInput(.end(request))))
    
            await store.receive(.updateRoutes(oldRoutes))
    
            await store.receive(.updateRoutes(routesWithSheetDismissed)) {
                $0.routes = routesWithSheetDismissed
            }
    
            await store.receive(.updateRoutes(updatedRoutes)) {
                $0.routes = updatedRoutes
            }
    
            await store.finish()
        }
}

