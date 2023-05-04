import XCTest
import ComposableArchitecture
import TCACoordinators
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

class IdentificationCoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockEIDInteractionManager: MockEIDInteractionManagerType!
    var mockStorageManager: MockStorageManagerType!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockPreviewEIDInteractionManager: MockPreviewEIDInteractionManagerType!
    var openedURL: URL?
    var urlOpener: ((URL) -> Void)!
    
    override func setUp() {
        mockEIDInteractionManager = MockEIDInteractionManagerType()
        mockStorageManager = MockStorageManagerType()
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        mockPreviewEIDInteractionManager = MockPreviewEIDInteractionManagerType()
        urlOpener = { self.openedURL = $0 }
        
        stub(mockStorageManager) {
            when($0.setupCompleted.set(any())).thenDoNothing()
        }
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
        
        stub(mockPreviewEIDInteractionManager) {
            $0.isDebugModeEnabled.get.thenReturn(false)
        }
    }
    
    override func tearDown() {
        openedURL = nil
    }
    
    func testOverviewLoadingSuccess() throws {
        let store = TestStore(initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL),
                              reducer: IdentificationCoordinator())
        store.dependencies.uuid = .incrementing
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        let request = IdentificationRequest.preview
        let certificateDescription = CertificateDescription.preview
        
        stub(mockEIDInteractionManager) {
            $0.retrieveCertificateDescription().then { _ in
                store.send(.eIDInteractionEvent(.success(.certificateDescriptionRetrieved(CertificateDescription.preview))))
            }
        }
        
        store.send(.eIDInteractionEvent(.success(.identificationRequestConfirmationRequested(request)))) {
            guard case .overview(.loading(var loadingState)) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            loadingState.identificationRequest = request
            $0.routes[0].screen = .overview(.loading(loadingState))
        }
        
        store.receive(.routeAction(0, action: .overview(.loading(.eIDInteractionEvent(.success(.identificationRequestConfirmationRequested(request)))))))
        
        store.receive(.routeAction(0, action: .overview(.loading(.eIDInteractionEvent(.success(.certificateDescriptionRetrieved(CertificateDescription.preview)))))))
        
        store.receive(.routeAction(0, action: .overview(.loading(.done(.preview, .preview))))) {
            $0.routes = [
                .sheet(.overview(.loaded(.init(id: UUID(number: 0),
                                               identificationInformation: .init(request: request,
                                                                                certificateDescription: certificateDescription)))))
            ]
        }
    }
    
    func testOverviewLoadedToPINEntry() throws {
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          states: [
                                                              .root(.overview(.loaded(.init(id: UUID(number: 0),
                                                                                            identificationInformation: identificationInformation))))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        store.send(.routeAction(0, action: .overview(.loaded(.confirm(identificationInformation))))) {
            $0.routes.append(.push(.personalPIN(IdentificationPersonalPIN.State(identificationInformation: identificationInformation))))
        }
    }
    
    func testPINEntryToScanFirstTime() throws {
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          states: [
                                                              .root(.personalPIN(.init(identificationInformation: identificationInformation)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        store.dependencies.storageManager = mockStorageManager
        stub(mockStorageManager) {
            $0.identifiedOnce.get.thenReturn(false)
        }
        
        store.send(.routeAction(0, action: .personalPIN(.done(identificationInformation: identificationInformation, pin: "123456")))) {
            $0.pin = "123456"
            $0.routes.append(.push(.scan(IdentificationPINScan.State(identificationInformation: identificationInformation, pin: "123456"))))
        }
    }
    
    func testPINEntryToScanAfterIdentifyingOnce() throws {
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          states: [
                                                              .root(.personalPIN(.init(identificationInformation: identificationInformation)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        store.dependencies.storageManager = mockStorageManager
        stub(mockStorageManager) {
            $0.identifiedOnce.get.thenReturn(true)
        }
        
        store.send(.routeAction(0, action: .personalPIN(.done(identificationInformation: identificationInformation, pin: "123456")))) {
            $0.pin = "123456"
            $0.routes.append(.push(.scan(IdentificationPINScan.State(
                identificationInformation: identificationInformation,
                pin: "123456",
                shared: SharedScan.State(startOnAppear: true)
            ))))
        }
    }
    
    func testScanSuccess() throws {
        let redirect = URL(string: "https://example.com")!
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.scan(.init(identificationInformation: identificationInformation,
                                                                                pin: pin)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        store.dependencies.urlOpener = urlOpener
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        
        stub(mockStorageManager) {
            $0.identifiedOnce.get.thenReturn(false)
            $0.identifiedOnce.set(any()).thenDoNothing()
        }
        
        store.send(.routeAction(0, action: .scan(.identifiedSuccessfully(redirectURL: redirect))))
        store.receive(.routeAction(0, action: IdentificationScreen.Action.scan(IdentificationPINScan.Action.dismiss)))
        
        XCTAssertEqual(redirect, openedURL)
        verify(mockStorageManager).setupCompleted.set(true)
        verify(mockStorageManager).identifiedOnce.set(true)
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification", action: "success"))
    }
    
    func testScanToIncorrectPIN() throws {
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.scan(.init(identificationInformation: identificationInformation,
                                                                                pin: pin)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        store.send(.routeAction(0, action: .scan(.wrongPIN(remainingAttempts: 2)))) {
            $0.routes.append(.sheet(.incorrectPersonalPIN(.init(error: .incorrect, remainingAttempts: 2))))
        }
    }
    
    func testScanToError() throws {
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.scan(.init(identificationInformation: identificationInformation,
                                                                                pin: pin)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        let errorState = ScanError.State(errorType: .cardBlocked, retry: false)
        store.send(.routeAction(0, action: .scan(.error(errorState)))) {
            $0.routes.append(.sheet(.error(errorState)))
        }
    }
    
    func testIncorrectPINToScan() throws {
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.scan(.init(identificationInformation: identificationInformation,
                                                                                pin: pin))),
                                                              .sheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State(enteredPIN: "112233", remainingAttempts: 2)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        store.send(.routeAction(1, action: .incorrectPersonalPIN(.done(pin: "112233")))) {
            guard case .scan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            $0.attempt += 1
            $0.pin = "112233"
            scanState.shared.attempt = $0.attempt
            scanState.pin = $0.pin!
            $0.routes = [.root(.scan(scanState))]
        }
    }
    
    func testOverviewIdentify() {
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          states: [
                                                              .root(.overview(.loading(IdentificationOverviewLoading.State())))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        store.dependencies.previewEIDInteractionManager = mockPreviewEIDInteractionManager
        
        let subject = PassthroughSubject<EIDInteractionEvent, EIDInteractionError>()
        stub(mockEIDInteractionManager) {
            $0.identify(tokenURL: demoTokenURL, messages: ScanOverlayMessages.identification).thenReturn(subject.eraseToAnyPublisher())
        }
        
        store.send(.routeAction(0, action: .overview(.loading(.identify))))
        
        subject.send(.identificationStarted)
        subject.send(completion: .finished)
        
        scheduler.advance()
        
        store.receive(.eIDInteractionEvent(.success(.identificationStarted)))
        store.receive(.routeAction(0, action: .overview(.loading(.eIDInteractionEvent(.success(.identificationStarted))))))
    }
    
    func testEndOnIncorrectPIN() {
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.scan(IdentificationPINScan.State(identificationInformation: identificationInformation, pin: pin))),
                                                              .sheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State(remainingAttempts: 2)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        store.send(.routeAction(1, action: .incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.Action.end))) {
            guard case .incorrectPersonalPIN(var incorrectPersonalPINState) = $0.routes[1].screen else { return XCTFail("Unexpected state") }
            incorrectPersonalPINState.alert = AlertState.confirmEndInIdentification(.confirmEnd)
            $0.routes[1].screen = .incorrectPersonalPIN(incorrectPersonalPINState)
        }
    }
    
    func testConfirmEndOnIncorrectPIN() {
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.scan(IdentificationPINScan.State(identificationInformation: identificationInformation, pin: pin))),
                                                              .sheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State(remainingAttempts: 2)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.send(.routeAction(1, action: .incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.Action.confirmEnd))) {
            $0.routes.removeLast()
        }
        
        scheduler.advance(by: 0.65)
        
        store.receive(.afterConfirmEnd)
    }
    
    func testSwipeToDismissTriggersConfirmation() {
        let pin = "123456"
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.overview(.loading(IdentificationOverviewLoading.State()))),
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        store.send(.swipeToDismiss) {
            $0.alert = AlertState.confirmEndInIdentification(.dismiss)
        }
    }
    
    func testEnterIncorrectPINToPinForgotten() throws {
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.scan(.init(identificationInformation: identificationInformation,
                                                                                pin: pin))),
                                                              .sheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State(enteredPIN: "112233", remainingAttempts: 2)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        store.send(.routeAction(1, action: .incorrectPersonalPIN(.done(pin: "112233")))) {
            guard case .scan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            $0.attempt += 1
            $0.pin = "112233"
            scanState.shared.attempt = $0.attempt
            scanState.pin = $0.pin!
            $0.routes = [.root(.scan(scanState))]
        }
        
        store.send(.routeAction(0, action: .scan(.requestCAN(identificationInformation)))) {
            $0.routes.append(.push(.identificationCANCoordinator(.init(identificationInformation: identificationInformation,
                                                                       pin: nil,
                                                                       attempt: $0.attempt,
                                                                       goToCanIntroScreen: false))))
        }
    }
    
    func testRequestPINAndCANFromImmediateThirdAttemptToCANIntro() throws {
        let pin = "123456"
        let identificationInformation = IdentificationInformation.preview
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          states: [
                                                              .root(.personalPIN(.init(identificationInformation: identificationInformation))),
                                                              .push(.scan(.init(identificationInformation: identificationInformation, pin: pin)))
                                                          ]),
            reducer: IdentificationCoordinator()
        )
        
        store.send(.routeAction(1, action: .scan(.requestCAN(identificationInformation)))) {
            $0.routes.append(.push(.identificationCANCoordinator(.init(identificationInformation: identificationInformation,
                                                                       pin: $0.pin!,
                                                                       attempt: $0.attempt,
                                                                       goToCanIntroScreen: true))))
        }
    }
    
    func testCancellationAndRestartingFlow() throws {
        let pin = "123456"
        
        let oldRoutes: [Route<IdentificationScreen.State>] = [
            .root(.scan(IdentificationPINScan.State(identificationInformation: .preview,
                                                    pin: pin,
                                                    shared: SharedScan.State(startOnAppear: true))))
        ]
        
        let store = TestStore(
            initialState: IdentificationCoordinator.State(tokenURL: demoTokenURL,
                                                          pin: pin,
                                                          attempt: 0,
                                                          states: oldRoutes),
            reducer: IdentificationCoordinator()
        )
        
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        store.dependencies.previewEIDInteractionManager = mockPreviewEIDInteractionManager
        
        let subject = PassthroughSubject<EIDInteractionEvent, EIDInteractionError>()
        stub(mockEIDInteractionManager) {
            $0.identify(tokenURL: demoTokenURL, messages: ScanOverlayMessages.identification).thenReturn(subject.eraseToAnyPublisher())
        }
        
        store.send(.routeAction(0, action: .scan(.scanEvent(.success(.identificationCancelled))))) {
            guard case .scan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            scanState.shouldRestartAfterCancellation = true
            $0.routes[0].screen = .scan(scanState)
        }
        
        store.send(.routeAction(0, action: .scan(.shared(.startScan(userInitiated: true))))) {
            guard case .scan(var scanState) = $0.routes[0].screen else { return XCTFail("Unexpected state") }
            scanState.shouldRestartAfterCancellation = false
            $0.routes[0].screen = .scan(scanState)
        }
        
        scheduler.advance()
        
        store.receive(.routeAction(0, action: .scan(.restartAfterCancellation)))
        
        stub(mockEIDInteractionManager) {
            $0.acceptAccessRights().thenDoNothing()
        }
        
        store.send(.routeAction(0, action: .scan(.scanEvent(.success(.identificationStarted)))))
        
        let identificationRequest = IdentificationRequest.preview
        store.send(.routeAction(0, action: .scan(.scanEvent(.success(.identificationRequestConfirmationRequested(identificationRequest))))))
        
        verify(mockEIDInteractionManager).acceptAccessRights()
        
        store.send(.routeAction(0, action: .scan(.dismiss))) // cancels the scanning
    }
}
