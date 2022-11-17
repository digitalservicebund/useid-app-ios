import XCTest
import ComposableArchitecture
import Cuckoo
import Combine

@testable import BundesIdent

class SetupCoordinatorTests: XCTestCase {
    
    var mockStorageManager: MockStorageManagerType!
    
    override func setUp() {
        mockStorageManager = MockStorageManagerType()
        
        stub(mockStorageManager) {
            when($0.setupCompleted.set(any())).thenDoNothing()
        }
    }
    
    func testEndTriggersConfirmation() {
        let store = TestStore(
            initialState: SetupCoordinator.State(),
            reducer: SetupCoordinator())
        
        store.send(.end) {
            $0.alert = AlertState(title: .init(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                                  message: .init(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                                  primaryButton: .destructive(.init(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm), action: .send(.confirmEnd)),
                                  secondaryButton: .cancel(.init(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
        }
    }
    
    func testMissingPINLetterNavigation() {
        let store = TestStore(initialState: SetupCoordinator.State(states: [.root(.intro(.init(tokenURL: nil))), .push(.transportPINIntro)]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .transportPINIntro(.choosePINLetterMissing))) {
            $0.routes = [.root(.intro(.init(tokenURL: nil))), .push(.transportPINIntro), .push(.missingPINLetter(.init()))]
        }
    }
    
    func testIntroPushesToTransportPINInput() {
        let store = TestStore(initialState: SetupCoordinator.State(states: [
            .root(.intro(.init(tokenURL: nil))),
            .push(.transportPINIntro)
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .transportPINIntro(.choosePINLetterAvailable))) {
            $0.routes = [
                .root(.intro(.init(tokenURL: nil))),
                .push(.transportPINIntro),
                .push(.transportPIN(.init()))]
        }
    }
    
    func testTransportPINPushesToPersonalPINIntro() {
        let transportPIN = "12345"
        let store = TestStore(initialState: SetupCoordinator.State(states: [
            .root(.transportPIN(.init()))
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .transportPIN(.done(transportPIN: transportPIN)))) {
            $0.transportPIN = transportPIN
            $0.routes = [
                .root(.transportPIN(.init())),
                .push(.personalPINIntro)
            ]
        }
    }
    
    func testPersonalIntroIntroPushesToPersonalInput() {
        let transportPIN = "12345"
        let store = TestStore(initialState: SetupCoordinator.State(states: [
            .root(.personalPINIntro)
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .personalPINIntro(.continue))) {
            $0.routes = [
                .root(.personalPINIntro),
                .push(.personalPINInput(.init()))
            ]
        }
    }
    
    func testPersonalInputPushesToPersonalPINConfirm() {
        let pin = "123456"
        
        let store = TestStore(initialState: SetupCoordinator.State(states: [
            .root(.personalPINInput(.init()))
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .personalPINInput(.done(pin: pin)))) {
            $0.routes = [
                .root(.personalPINInput(.init())),
                .push(.personalPINConfirm(.init(enteredPIN1: pin)))
            ]
        }
    }
    
    func testPersonalPINConfirmMismatchPopsView() {
        let pin = "123456"
        let store = TestStore(initialState: SetupCoordinator.State(states: [
            .root(.personalPINInput(.init())),
            .push(.personalPINConfirm(.init(enteredPIN1: pin)))
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(1, action: .personalPINConfirm(.confirmMismatch))) {
            $0.routes = [
                .root(.personalPINInput(.init()))
            ]
        }
    }
    
    func testPersonalPINConfirmPopsAndPushesScan() {
        let pin = "123456"
        let transportPIN = "12345"
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                  states: [
            .root(.personalPINInput(.init())),
            .push(.personalPINConfirm(.init(enteredPIN1: pin)))
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(1, action: .personalPINConfirm(.done(pin: pin)))) {
            $0.routes = [
                .root(.personalPINInput(.init())),
                .push(.scan(.init(transportPIN: $0.transportPIN, newPIN: pin)))
            ]
        }
    }
    
    func testScanSuccesfulPushesToSetupDone() {
        let pin = "123456"
        let transportPIN = "12345"
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                  states: [
            .root(.scan(.init(transportPIN: transportPIN, newPIN: pin)))
        ]),
                              reducer: SetupCoordinator())
        store.dependencies.storageManager = mockStorageManager
        
        store.send(.routeAction(0, action: .scan(.scannedSuccessfully))) {
            $0.routes = [
                .root(.scan(.init(transportPIN: $0.transportPIN, newPIN: pin))),
                .push(.done(SetupDone.State(tokenURL: $0.tokenURL)))
            ]
        }
    }
    
    func testScanErrorPresentsError() {
        let pin = "123456"
        let transportPIN = "12345"
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                  states: [
            .root(.scan(.init(transportPIN: transportPIN, newPIN: pin)))
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .scan(.error(.init(errorType: .help, retry: false))))) {
            $0.routes = [
                .root(.scan(.init(transportPIN: $0.transportPIN, newPIN: pin))),
                .sheet(.error(.init(errorType: .help, retry: false)))
            ]
        }
    }
    
    func testScanWrongTransportPINPresentsIncorrectTransportPIN() {
        let pin = "123456"
        let transportPIN = "12345"
        var remainingAttempts = 3
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                  states: [
            .root(.scan(.init(transportPIN: transportPIN, newPIN: pin)))
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .scan(.wrongTransportPIN(remainingAttempts: remainingAttempts)))) {
            $0.routes = [
                .root(.scan(.init(transportPIN: $0.transportPIN, newPIN: pin))),
                .sheet(.incorrectTransportPIN(.init(remainingAttempts: remainingAttempts)))
            ]
        }
    }
    
    func testIncorrectTransportPINDoneDismissesSheetAndStartsNewScan() {
        let pin = "123456"
        let transportPIN = "12345"
        let newTransportPIN = "54321"
        var remainingAttempts = 3
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                  states: [
            .root(.scan(.init(transportPIN: transportPIN, newPIN: pin))),
            .sheet(.incorrectTransportPIN(.init(remainingAttempts: remainingAttempts)))
        ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(1, action: .incorrectTransportPIN(.done(transportPIN: newTransportPIN)))) {
            $0.attempt = 1
            $0.transportPIN = newTransportPIN
            $0.routes = [
                .root(.scan(.init(transportPIN: newTransportPIN, newPIN: pin, shared: .init(attempt: 1))))
            ]
        }
    }
}
