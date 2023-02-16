import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

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
            reducer: SetupCoordinator()
        )
        
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
                .push(.transportPIN(.init()))
            ]
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
        let remainingAttempts = 3
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
        let remainingAttempts = 3
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
    
    func testInitiateScan() {
        let oldPIN = "12345"
        let newPIN = "123456"
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: oldPIN,
                                                                   states: [
                                                                       .root(.scan(SetupScan.State(transportPIN: oldPIN, newPIN: newPIN)))
                                                                   ]),
                              reducer: SetupCoordinator())
        
        let mockPreviewIDInteractionManager = MockPreviewIDInteractionManagerType()
        let mockIDInteractionManager = MockIDInteractionManagerType()
        
        let scheduler = DispatchQueue.test
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        
        stub(mockPreviewIDInteractionManager) {
            $0.isDebugModeEnabled.get.thenReturn(false)
        }
        
        stub(mockIDInteractionManager) {
            $0.changePIN(nfcMessagesProvider: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                scheduler.schedule {
                    subject.send(.authenticationStarted)
                    subject.send(completion: .finished)
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.routeAction(0, action: .scan(.shared(.initiateScan))))
        
        scheduler.advance()
        
        store.receive(.idInteractionEvent(.success(.authenticationStarted)))
        
        store.receive(.routeAction(0, action: .scan(.scanEvent(.success(.authenticationStarted))))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail() }
            scanState.shared.isScanning = true
            $0.states[0].screen = .scan(scanState)
        }
    }
    
    func testStartScanTracking() {
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: "12345",
                                                                   states: [
                                                                       .root(.scan(SetupScan.State(transportPIN: "12345", newPIN: "123456")))
                                                                   ]), reducer: SetupCoordinator())
        
        let scheduler = DispatchQueue.test
        let mockAnalyticsClient = MockAnalyticsClient()
        let mockIDInteractionManager = MockIDInteractionManagerType()
        let mockPreviewIDInteractionManager = MockPreviewIDInteractionManagerType()
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
        
        stub(mockIDInteractionManager) { mock in
            mock.changePIN(nfcMessagesProvider: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                scheduler.schedule {
                    subject.send(completion: .finished)
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        stub(mockPreviewIDInteractionManager) {
            $0.isDebugModeEnabled.get.thenReturn(false)
        }
        
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        
        store.send(.routeAction(0, action: .scan(.shared(.initiateScan))))
        
        scheduler.advance()
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
}
