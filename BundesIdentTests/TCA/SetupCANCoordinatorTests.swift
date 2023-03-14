import Analytics
import Combine
import ComposableArchitecture
import Cuckoo
import TCACoordinators
import XCTest

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
                                                    attempt: 0,
                                                    states: [
                                                        .root(.canIntro(CANIntro.State(shouldDismiss: true)))
                                                    ]),
            reducer: SetupCANCoordinator()
        )
        
        store.send(.routeAction(0, action: .canIntro(.showInput(shouldDismiss: true)))) {
            $0.routes.append(.push(.canInput(CANInput.State(pushesToPINEntry: false))))
        }
        
        store.send(.routeAction(1, action: .canInput(.done(can: can, pushesToPINEntry: false)))) {
            $0.can = can
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
            $0.routes.append(.sheet(.canIncorrectInput(.init())))
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
                                                    attempt: 0,
                                                    states: [
                                                        .root(.canIntro(CANIntro.State(shouldDismiss: true)))
                                                    ]),
            reducer: SetupCANCoordinator()
        )
        
        store.send(.routeAction(0, action: .canIntro(.showInput(shouldDismiss: false)))) {
            $0.routes.append(.push(.canInput(CANInput.State(pushesToPINEntry: true))))
        }
        
        store.send(.routeAction(1, action: .canInput(.done(can: can, pushesToPINEntry: true)))) {
            $0.can = can
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
        let can = "333333"
        let canAndChangedPINCallback = CANAndChangedPINCallback(id: UUID(number: 0)) { _ in }
        let store = TestStore(
            initialState: SetupCANCoordinator.State(pin: pin,
                                                    transportPIN: transportPIN,
                                                    oldTransportPIN: transportPIN,
                                                    canAndChangedPINCallback: canAndChangedPINCallback,
                                                    tokenURL: demoTokenURL,
                                                    attempt: 0,
                                                    states: [
                                                        .root(.canScan(SetupCANScan.State(transportPIN: transportPIN,
                                                                                          newPIN: pin,
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
