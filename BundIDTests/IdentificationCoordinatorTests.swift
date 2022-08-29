import XCTest
import ComposableArchitecture
import Cuckoo
import Combine

@testable import BundID

class IdentificationCoordinatorTests: XCTestCase {
    
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
        environment = AppEnvironment.mocked(mainQueue: scheduler.eraseToAnyScheduler(),
                                            uuidFactory: uuidFactory,
                                            idInteractionManager: mockIDInteractionManager)
    }
    
    func testOverviewLoadingSuccess() throws {
        let store = TestStore(initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL),
                              reducer: identificationCoordinatorReducer,
                              environment: environment)
        
        let request = EIDAuthenticationRequest.preview
        let closure = { (attributes: FlaggedAttributes) in }
        let callback = IdentifiableCallback<FlaggedAttributes>(id: UUID(number: 0), callback: closure)
        
        store.send(.idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(request, closure))))
        
        store.receive(.routeAction(0, action: .overview(.loading(.idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(request, closure)))))))
        
        store.receive(.routeAction(0, action: .overview(.loading(.done(request, callback))))) {
            $0.states = [
                .sheet(.overview(.loaded(.init(id: UUID(number: 1), request: request, handler: callback))))
            ]
        }
    }
    
    func testOverviewLoadedToPINEntry() throws {
        let request = EIDAuthenticationRequest.preview
        let closure = { (attributes: FlaggedAttributes) in }
        let callback = IdentifiableCallback<FlaggedAttributes>(id: UUID(number: 0), callback: closure)
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         states: [
                                                            .root(.overview(.loaded(.init(id: UUID(number: 0),
                                                                                          request: request,
                                                                                          handler: callback))))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        let pinCallback = PINCallback(id: UUID(number: 1), callback: { pin in })
        store.send(.routeAction(0, action: .overview(.loaded(.callbackReceived(request, pinCallback))))) {
            $0.states.append(.push(.personalPIN(IdentificationPersonalPINState(request: request, callback: pinCallback))))
        }
    }
    
    func testPINEntryToScan() throws {
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         states: [
                                                            .root(.personalPIN(.init(request: request,
                                                                                     callback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .personalPIN(.done(request: request, pin: "123456", pinCallback: callback)))) {
            $0.pin = "123456"
            $0.states.append(.push(.scan(IdentificationScanState(request: request, pin: "123456", pinCallback: callback))))
        }
    }
    
    func testScanToDoneWithoutRedirect() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .scan(.identifiedSuccessfullyWithoutRedirect(request))))
    }
    
    func testScanToDoneWithRedirect() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .scan(.identifiedSuccessfullyWithRedirect(request, redirectURL: "https://example.com")))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail("Unexpected state") }
            scanState.isScanning = false
            $0.states = [.root(.scan(scanState)), .push(.done(.init(request: request, redirectURL: "https://example.com")))]
        }
    }
    
    func testScanToIncorrectPIN() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .scan(.wrongPIN(remainingAttempts: 2)))) {
            $0.states.append(.sheet(.incorrectPersonalPIN(.init(error: .incorrect, remainingAttempts: 2))))
        }
    }
    
    func testScanToError() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(0, action: .scan(.error(.cardBlocked)))) {
            $0.states.append(.push(.cardError(.init(errorType: .cardBlocked))))
        }
    }
    
    func testIncorrectPINToScan() throws {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(.init(request: request,
                                                                              pin: pin,
                                                                              pinCallback: callback))),
                                                            .sheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPINState(enteredPIN: "112233", remainingAttempts: 2)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment)
        
        store.send(.routeAction(1, action: .incorrectPersonalPIN(.done(pin: "112233")))) {
            guard case .scan(var scanState) = $0.states[0].screen else { return XCTFail("Unexpected state") }
            $0.attempt += 1
            $0.pin = "112233"
            scanState.attempt = $0.attempt
            scanState.pin = $0.pin!
            $0.states = [.root(.scan(scanState))]
        }
    }
    
    func testOverviewIdentify() {
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         states: [
                                                            .root(.overview(.loading(IdentificationOverviewLoadingState())))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment
        )
        
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        stub(mockIDInteractionManager) {
            $0.identify(tokenURL: demoTokenURL, nfcMessages: NFCMessages.identification).thenReturn(subject.eraseToAnyPublisher())
        }
        
        store.send(.routeAction(0, action: .overview(.identify)))
        
        subject.send(.authenticationStarted)
        subject.send(completion: .finished)
        
        scheduler.advance()
        
        store.receive(.idInteractionEvent(.success(.authenticationStarted)))
        store.receive(.routeAction(0, action: .overview(.loading(.idInteractionEvent(.success(.authenticationStarted))))))
    }
    
    func testEndOnIncorrectPIN() {
        let pin = "123456"
        let request = EIDAuthenticationRequest.preview
        let callback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.scan(IdentificationScanState(request: request, pin: pin, pinCallback: callback))),
                                                            .sheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPINState(remainingAttempts: 2)))
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment
        )
        
        store.send(.routeAction(1, action: .incorrectPersonalPIN(IdentificationIncorrectPersonalPINAction.confirmEnd))) {
            $0.states.removeLast()
        }
        
        scheduler.advance(by: 0.65)
        
        store.receive(.afterConfirmEnd)
    }
    
    func testEndTriggersConfirmation() {
        let pin = "123456"
        let store = TestStore(
            initialState: IdentificationCoordinatorState(tokenURL: demoTokenURL,
                                                         pin: pin,
                                                         states: [
                                                            .root(.overview(.loading(IdentificationOverviewLoadingState()))),
                                                         ]),
            reducer: identificationCoordinatorReducer,
            environment: environment
        )
        
        store.send(.end) {
            $0.alert = AlertState(title: .init(verbatim: L10n.Identification.ConfirmEnd.title), message: .init(verbatim: L10n.Identification.ConfirmEnd.message), primaryButton: .destructive(.init(verbatim: L10n.Identification.ConfirmEnd.confirm), action: .send(.confirmEnd)), secondaryButton: .cancel(.init(verbatim: L10n.General.cancel)))
        }
    }
}
