import XCTest
import ComposableArchitecture
import TCACoordinators
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

class SetupCANCoordinatorTests: XCTestCase {
    func testCANIntroFromImmediateThirdAttemptToCanScan() throws {
        let pin = "123456"
        let transportPIN = "12345"
        let can = "123456"
        let canAndChangedPINCallback = CANAndChangedPINCallback(id: UUID(number: 0), callback: { _ in })
        let newCANAndChangedPINCallback = CANAndChangedPINCallback(id: UUID(number: 1), callback: { _ in })
        let store = TestStore(
            initialState: SetupCANCoordinator.State(pin: pin,
                                                    transportPIN: transportPIN,
                                                    oldTransportPIN: transportPIN,
                                                    canAndChangedPINCallback: canAndChangedPINCallback,
                                                    tokenURL: demoTokenURL,
                                                    _shared: SharedCANCoordinator.State(
                                                        attempt: 0
                                                    ),
                                                    states: [
                                                        .root(.shared(.canIntro(CANIntro.State(isRootOfCANFlow: true))))
                                                    ]),
            reducer: SetupCANCoordinator()
        )
        
        store.send(.routeAction(0, action: .shared(.canIntro(.showInput(isRootOfCANFlow: true))))) {
            $0.shared.swipeToDismiss = SwipeToDismissState.allowAfterConfirmation(
                title: L10n.Identification.ConfirmEnd.title,
                body: L10n.Identification.ConfirmEnd.message,
                confirm: L10n.Identification.ConfirmEnd.confirm,
                deny: L10n.General.cancel
            )
        }
        
        store.receive(.shared(.push(.canInput(CANInput.State(pushesToPINEntry: false))))) {
            $0.routes.append(.push(.shared(.canInput(CANInput.State(pushesToPINEntry: false)))))
        }
        
        store.send(.routeAction(1, action: .shared(.canInput(.done(can: can, pushesToPINEntry: false))))) {
            $0.shared.can = can
            $0.routes.append(.push(
                .canScan(SetupCANScan.State(transportPIN: transportPIN,
                                            newPIN: pin,
                                            can: can,
                                            canAndChangedPINCallback: canAndChangedPINCallback,
                                            shared: .init(showInstructions: false)))
            ))
        }
        
        store.send(.routeAction(2, action: .canScan(.incorrectCAN(callback: newCANAndChangedPINCallback)))) {
            $0.canAndChangedPINCallback = newCANAndChangedPINCallback
            $0.routes.append(.sheet(.shared(.canIncorrectInput(.init()))))
        }
    }
    
    func testCANIntroFromThirdAttemptToCanScan() throws {
        let pin = "123456"
        let transportPIN = "12345"
        let can = "123456"
        let canAndChangedPINCallback = CANAndChangedPINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: SetupCANCoordinator.State(pin: pin,
                                                    transportPIN: transportPIN,
                                                    oldTransportPIN: transportPIN,
                                                    canAndChangedPINCallback: canAndChangedPINCallback,
                                                    tokenURL: demoTokenURL,
                                                    _shared: SharedCANCoordinator.State(
                                                        attempt: 0
                                                    ),
                                                    states: [
                                                        .root(.shared(.canIntro(CANIntro.State(isRootOfCANFlow: true))))
                                                    ]),
            reducer: SetupCANCoordinator()
        )
        
        store.send(.routeAction(0, action: .shared(.canIntro(.showInput(isRootOfCANFlow: false))))) {
            $0.shared.swipeToDismiss = SwipeToDismissState.allowAfterConfirmation(
                title: L10n.Identification.ConfirmEnd.title,
                body: L10n.Identification.ConfirmEnd.message,
                confirm: L10n.Identification.ConfirmEnd.confirm,
                deny: L10n.General.cancel
            )
        }
        
        store.receive(.shared(.push(.canInput(CANInput.State(pushesToPINEntry: true))))) {
            $0.routes.append(.push(.shared(.canInput(CANInput.State(pushesToPINEntry: true)))))
        }
        
        store.send(.routeAction(1, action: .shared(.canInput(.done(can: can, pushesToPINEntry: true))))) {
            $0.shared.can = can
            $0.routes.append(.push(
                .canTransportPINInput(SetupTransportPIN.State(enteredPIN: "", digits: 5, attempts: 1))
            ))
        }
        
        let newTransportPIN = "67890"
        store.send(.routeAction(2, action: .canTransportPINInput(SetupTransportPIN.Action.done(transportPIN: newTransportPIN)))) {
            $0.transportPIN = newTransportPIN
            $0.routes.append(.push(
                .canScan(SetupCANScan.State(transportPIN: newTransportPIN,
                                            newPIN: pin,
                                            can: can,
                                            canAndChangedPINCallback: canAndChangedPINCallback,
                                            shared: .init(showInstructions: false)))
            ))
        }
    }
    
    func testSuccessfulScan() {
        let pin = "111111"
        let transportPIN = "12345"
        let newPIN = "222222"
        let can = "333333"
        let canAndChangedPINCallback = CANAndChangedPINCallback(id: UUID(number: 0)) { _ in }
        let store = TestStore(
            initialState: SetupCANCoordinator.State(pin: pin,
                                                    transportPIN: transportPIN,
                                                    oldTransportPIN: transportPIN,
                                                    canAndChangedPINCallback: canAndChangedPINCallback,
                                                    tokenURL: demoTokenURL,
                                                    _shared: SharedCANCoordinator.State(
                                                        attempt: 0
                                                    ),
                                                    states: [
                                                        .root(.canScan(SetupCANScan.State(transportPIN: transportPIN,
                                                                                          newPIN: newPIN,
                                                                                          can: can,
                                                                                          canAndChangedPINCallback: canAndChangedPINCallback)))
                                                    ]),
            reducer: SetupCANCoordinator()
        )
        
        let mockStorageManager = MockStorageManagerType()
        stub(mockStorageManager) {
            $0.setupCompleted.set(any()).thenDoNothing()
        }
        store.dependencies.storageManager = mockStorageManager
        
        store.send(.routeAction(0, action: .canScan(.scannedSuccessfully))) {
            $0.routes.push(.setupCoordinator(SetupCoordinator.State(tokenURL: demoTokenURL,
                                                                    states: [
                                                                        .root(.done(SetupDone.State(tokenURL: demoTokenURL)))
                                                                    ])))
        }
        
        verify(mockStorageManager).setupCompleted.set(true)
    }
}
