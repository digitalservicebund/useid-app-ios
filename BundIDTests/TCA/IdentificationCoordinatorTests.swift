import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundID

class IdentificationCoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockIDInteractionManager: MockIDInteractionManagerType!
    var mockStorageManager: MockStorageManagerType!
    var mockAnalyticsClient: MockAnalyticsClient!
    
    var openedURL: URL?
    var environment: AppEnvironment!
    var uuidCount = 0
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        mockIDInteractionManager = MockIDInteractionManagerType()
        mockStorageManager = MockStorageManagerType()
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        environment = AppEnvironment.mocked(mainQueue: scheduler.eraseToAnyScheduler(),
                                            uuidFactory: uuidFactory,
                                            idInteractionManager: mockIDInteractionManager,
                                            storageManager: mockStorageManager,
                                            analytics: mockAnalyticsClient,
                                            urlOpener: { self.openedURL = $0 })
        
        stub(mockStorageManager) {
            when($0.updateSetupCompleted(any())).thenDoNothing()
        }
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }
    
    override func tearDown() {
        openedURL = nil
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
            $0.routes = [
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
            $0.routes.append(.push(.personalPIN(IdentificationPersonalPINState(request: request, callback: pinCallback))))
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
            $0.routes.append(.push(.scan(IdentificationScanState(request: request, pin: "123456", pinCallback: callback))))
        }
    }
    
    func testScanSuccess() throws {
        let redirect = URL(string: "https://example.com")!
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
        
        store.send(.routeAction(0, action: .scan(.identifiedSuccessfully(redirectURL: redirect))))
        store.receive(.routeAction(0, action: IdentificationScreenAction.scan(IdentificationScanAction.end)))
        
        XCTAssertEqual(redirect, openedURL)
        verify(mockStorageManager).updateSetupCompleted(true)
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification", action: "success"))
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
            $0.routes.append(.sheet(.incorrectPersonalPIN(.init(error: .incorrect, remainingAttempts: 2))))
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
        
        let errorState = ScanErrorState(errorType: .cardBlocked, retry: false)
        store.send(.routeAction(0, action: .scan(.error(errorState)))) {
            $0.routes.append(.sheet(.error(errorState)))
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
            guard case .scan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            $0.attempt += 1
            $0.pin = "112233"
            scanState.attempt = $0.attempt
            scanState.pin = $0.pin!
            $0.routes = [.root(.scan(scanState))]
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
        
        store.send(.routeAction(0, action: .overview(.loading(.identify))))
        
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
            $0.routes.removeLast()
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
            $0.alert = AlertState(title: .init(verbatim: L10n.Identification.ConfirmEnd.title),
                                  message: .init(verbatim: L10n.Identification.ConfirmEnd.message),
                                  primaryButton: .destructive(.init(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                                              action: .send(.confirmEnd)),
                                  secondaryButton: .cancel(.init(verbatim: L10n.Identification.ConfirmEnd.deny)))
        }
    }
}
