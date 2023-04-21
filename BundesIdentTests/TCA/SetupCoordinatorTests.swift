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
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                   states: [
                                                                       .root(.scan(.init(transportPIN: transportPIN, newPIN: pin)))
                                                                   ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .scan(.wrongTransportPIN))) {
            $0.routes = [
                .root(.scan(.init(transportPIN: $0.transportPIN, newPIN: pin))),
                .sheet(.incorrectTransportPIN(.init()))
            ]
        }
    }
    
    func testIncorrectTransportPINDoneDismissesSheetAndStartsNewScan() {
        let pin = "123456"
        let transportPIN = "12345"
        let newTransportPIN = "54321"
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                   states: [
                                                                       .root(.scan(.init(transportPIN: transportPIN, newPIN: pin))),
                                                                       .sheet(.incorrectTransportPIN(.init()))
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
            $0.changePIN(messages: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                scheduler.schedule {
                    subject.send(.authenticationStarted)
                    subject.send(completion: .finished)
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.routeAction(0, action: .scan(.shared(.initiateScan)))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail() }
            scanState.isScanInitiated = true
            $0.states[0].screen = .scan(scanState)
        }
        
        scheduler.advance()
        
        store.receive(.idInteractionEvent(.success(.authenticationStarted)))
        
        store.receive(.routeAction(0, action: .scan(.scanEvent(.success(.authenticationStarted)))))
    }
    
    func testStartingCANFlow() {
        let oldPIN = "12345"
        let newPIN = "123456"
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: oldPIN,
                                                                   tokenURL: demoTokenURL,
                                                                   states: [
                                                                       .root(.scan(SetupScan.State(transportPIN: oldPIN, newPIN: newPIN, shared: SharedScan.State())))
                                                                   ]),
                              reducer: SetupCoordinator())
        
        let mockPreviewIDInteractionManager = MockPreviewIDInteractionManagerType()
        let mockIDInteractionManager = MockIDInteractionManagerType()
        
        let scheduler = DispatchQueue.test
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        store.dependencies.uuid = .incrementing
        
        stub(mockPreviewIDInteractionManager) {
            $0.isDebugModeEnabled.get.thenReturn(false)
        }
        
        let requestCANAndChangedPINCallback: (String, String, String) -> Void = { _, _, _ in }
        
        store.send(.routeAction(0, action: .scan(.scanEvent(.success(.canRequested))))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail() }
            $0.states[0].screen = .scan(scanState)
        }
        
        scheduler.advance(by: .seconds(2))
        
        let canAndChangedPINCallback = CANAndChangedPINCallback(id: .zero) { payload in }
        
        store.receive(.routeAction(0, action: .scan(.requestCANAndChangedPIN(pin: newPIN)))) {
            $0.states.append(.push(.setupCANCoordinator(SetupCANCoordinator.State(
                pin: newPIN,
                transportPIN: oldPIN,
                oldTransportPIN: oldPIN,
                tokenURL: demoTokenURL,
                attempt: 0,
                states: [
                    .root(.canIntro(CANIntro.State(shouldDismiss: true)))
                ]
            ))))
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
            mock.changePIN(messages: any()).then { _ in
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
        
        store.send(.routeAction(0, action: .scan(.shared(.initiateScan)))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail() }
            scanState.isScanInitiated = true
            $0.states[0].screen = .scan(scanState)
        }

        scheduler.advance()
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
    
    func testCancelingOnConfirmTransportPINAsksForConfirmation() throws {
        let setupCANCoordinatorState = SetupCANCoordinator.State(pin: "123456", oldTransportPIN: "12345", attempt: 0, states: [
            .root(.canConfirmTransportPIN(.init(transportPIN: "12345")))
        ])
        
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: "12345",
                                                                   states: [
                                                                       .root(.setupCANCoordinator(setupCANCoordinatorState))
                                                                   ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .setupCANCoordinator(.swipeToDismiss))) {
            guard case .setupCANCoordinator(var setupCANCoordinatorState) = $0.states[0].screen else { return XCTFail() }
            setupCANCoordinatorState.alert = AlertState.confirmEndInSetup(.dismiss)
            $0.states[0].screen = .setupCANCoordinator(setupCANCoordinatorState)
        }
    }
    
    func testCancelingOnCANIntroAsksForConfirmation() throws {
        let setupCANCoordinatorState = SetupCANCoordinator.State(pin: "123456", oldTransportPIN: "12345", attempt: 0, states: [
            .root(.canIntro(.init(shouldDismiss: true)))
        ])
        
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: "12345",
                                                                   states: [
                                                                       .root(.setupCANCoordinator(setupCANCoordinatorState))
                                                                   ]),
                              reducer: SetupCoordinator())
        
        store.send(.routeAction(0, action: .setupCANCoordinator(.swipeToDismiss))) {
            guard case .setupCANCoordinator(var setupCANCoordinatorState) = $0.states[0].screen else { return XCTFail() }
            setupCANCoordinatorState.alert = AlertState.confirmEndInSetup(.dismiss)
            $0.states[0].screen = .setupCANCoordinator(setupCANCoordinatorState)
        }
    }
    
    func testInitiatingScanOnCAN() throws {
        let transportPIN = "12345"
        let newPIN = "123456"
        let can = "111111"
        let setupCANCoordinatorState = SetupCANCoordinator.State(pin: newPIN, oldTransportPIN: transportPIN, attempt: 0, states: [
            .root(.canScan(SetupCANScan.State(transportPIN: transportPIN, newPIN: newPIN, can: can)))
        ])
        
        let store = TestStore(initialState: SetupCoordinator.State(transportPIN: transportPIN,
                                                                   states: [
                                                                       .root(.setupCANCoordinator(setupCANCoordinatorState))
                                                                   ]),
                              reducer: SetupCoordinator())
        
        let scheduler = DispatchQueue.test
        let mockPreviewIDInteractionManager = MockPreviewIDInteractionManagerType()
        let mockIDInteractionManager = MockIDInteractionManagerType()
        let mockAnalyticsClient = MockAnalyticsClient()
        
        stub(mockPreviewIDInteractionManager) {
            $0.isDebugModeEnabled.get.thenReturn(false)
        }
        
        stub(mockIDInteractionManager) {
            $0.changePIN(messages: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                scheduler.schedule {
                    subject.send(.authenticationStarted)
                    subject.send(completion: .finished)
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
        
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        store.dependencies.analytics = mockAnalyticsClient
        
        store.send(.routeAction(0, action: .setupCANCoordinator(.routeAction(0, action: .canScan(.shared(.initiateScan))))))
        
        scheduler.advance()
        
        store.receive(.idInteractionEvent(.success(.authenticationStarted)))
        
        store.receive(.routeAction(0, action: .setupCANCoordinator(.routeAction(0, action: .canScan(.scanEvent(.success(.authenticationStarted)))))))
        
        verify(mockIDInteractionManager).changePIN(messages: any())
        verify(mockAnalyticsClient).track(event: any())
    }

}
