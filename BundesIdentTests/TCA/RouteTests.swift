import Combine
import ComposableArchitecture
import Cuckoo
import TCACoordinators
import XCTest

@testable import Analytics
@testable import BundesIdent
@testable import MatomoTracker

extension CustomDimension: Matchable {
    public var matcher: ParameterMatcher<CustomDimension> {
        ParameterMatcher { tested in
            index == tested.index &&
                value == tested.value
        }
    }
}

extension URL: OptionalMatchable {
    public var optionalMatcher: ParameterMatcher<URL?> {
        ParameterMatcher { tested in
            self.absoluteString == tested?.absoluteString
        }
    }
}

final class RouteTests: XCTestCase {
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MatomoAnalyticsClient!
    var mockIssueTracker: MockIssueTracker!
    var mockEIDInteractionManager = MockEIDInteractionManagerType()
    var mockStorageManager = MockStorageManagerType()
    var mockMatomoTracker = MockMatomoTrackerProtocol()
    var openedURL: URL?
    var urlOpener: ((URL) -> Void)!

    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MatomoAnalyticsClient(tracker: mockMatomoTracker)
        mockIssueTracker = MockIssueTracker()
        urlOpener = { self.openedURL = $0 }

        stub(mockIssueTracker) {
            $0.addBreadcrumb(crumb: any()).thenDoNothing()
            $0.capture(error: any()).thenDoNothing()
        }

        stub(mockMatomoTracker) {
            $0.track(view: any(), url: any()).thenDoNothing()
            $0.track(eventWithCategory: any(), action: any(), name: any(), value: any(), dimensions: any(), url: any()).thenDoNothing()
            $0.reset().thenDoNothing()
        }

        stub(mockStorageManager) {
            $0.identifiedOnce.get.thenReturn(true)
            $0.identifiedOnce.set(any()).thenDoNothing()
            $0.setupCompleted.get.thenReturn(true)
            $0.setupCompleted.set(any()).thenDoNothing()
        }
        
        stub(mockEIDInteractionManager) {
            $0.interrupt().thenDoNothing()
            $0.setPIN(any()).thenDoNothing()
            $0.setCAN(any()).thenDoNothing()
            $0.retrieveCertificateDescription().thenDoNothing()
        }
    }

    func testMissingPINLetterRoutes() {
        let root = Route<Screen.State>.root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: Coordinator.State(routes: [root]),
                              reducer: Coordinator())
        store.exhaustivity = .off
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()

        store.send(.onAppear)

        verify(mockMatomoTracker).reset()
        verify(mockMatomoTracker).track(view: [], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(0, action: .home(.triggerSetup)))

        verify(mockMatomoTracker)
            .track(eventWithCategory: "firstTimeUser",
                   action: "buttonPressed",
                   name: "start",
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)
        verify(mockMatomoTracker)
            .track(eventWithCategory: "firstTimeUser",
                   action: "setupIntroOpened",
                   name: "home",
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)

        verify(mockMatomoTracker).track(view: ["firstTimeUser", "intro"], url: URL?.none)
        endInteraction(mockMatomoTracker)
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseStartSetup)))))

        verify(mockMatomoTracker).track(view: ["firstTimeUser", "PINLetter"], url: URL?.none)
        verify(mockMatomoTracker)
            .track(eventWithCategory: "firstTimeUser",
                   action: "buttonPressed",
                   name: "startSetup",
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(1, action: .transportPINIntro(.choosePINLetterMissing)))))

        verify(mockMatomoTracker).track(view: ["firstTimeUser", "missingPINLetter"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(2, action: .missingPINLetter(.openExternalLink)))))
        verify(mockMatomoTracker)
            .track(eventWithCategory: "firstTimeUser",
                   action: "externalLinkOpened",
                   name: "PINLetter",
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)
        endInteraction(mockMatomoTracker)
    }

    func testSetupScanHappyPathRoutes() {
        let pin = "123456"
        let transportPIN = "123456"
        let root = Route<Screen.State>.root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: Coordinator.State(routes: [root]),
                              reducer: Coordinator())
        store.exhaustivity = .off
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()

        store.send(.onAppear)

        verify(mockMatomoTracker).reset()
        verify(mockMatomoTracker).track(view: [], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(0, action: .home(.triggerSetup)))

        verify(mockMatomoTracker)
            .track(eventWithCategory: "firstTimeUser",
                   action: "buttonPressed",
                   name: "start",
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)
        verify(mockMatomoTracker)
            .track(eventWithCategory: "firstTimeUser",
                   action: "setupIntroOpened",
                   name: "home",
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)

        verify(mockMatomoTracker).track(view: ["firstTimeUser", "intro"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(0, action: .intro(.chooseStartSetup)))))

        verify(mockMatomoTracker).track(view: ["firstTimeUser", "PINLetter"], url: URL?.none)
        verify(mockMatomoTracker)
            .track(eventWithCategory: "firstTimeUser",
                   action: "buttonPressed",
                   name: "startSetup",
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(1, action: .transportPINIntro(.choosePINLetterAvailable)))))

        verify(mockMatomoTracker).track(view: ["firstTimeUser", "transportPIN"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(2, action: .transportPIN(.done(transportPIN: transportPIN))))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "personalPINIntro"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(3, action: .personalPINIntro(.continue)))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "personalPINInput"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(4, action: .personalPINInput(.done(pin: pin))))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "personalPINConfirm"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(5, action: .personalPINConfirm(.done(pin: pin))))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "scan"], url: URL?.none)
        endInteraction(mockMatomoTracker)
        XCTAssertEqual(store.state.routes, setupScanRoutes(pin: pin, transportPIN: transportPIN))

        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(5, action: .scan(.scannedSuccessfully)))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "done"], url: URL?.none)
        endInteraction(mockMatomoTracker)
    }

    func testScanErrorHelpRoutes() {
        let pin = "123456"
        let transportPIN = "123456"
        let store = testStore(setupScanRoutes(pin: pin, transportPIN: transportPIN))
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(5, action: .scan(.error(.init(errorType: .help, retry: true)))))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "scanHelp"], url: URL?.none)
        verify(mockMatomoTracker).reset()
        endInteraction(mockMatomoTracker)
    }

    func testScanErrorCardDeactivatedRoutes() {
        let pin = "123456"
        let transportPIN = "123456"
        let store = testStore(setupScanRoutes(pin: pin, transportPIN: transportPIN))
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(5, action: .scan(.error(.init(errorType: .cardDeactivated, retry: true)))))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "cardDeactivated"], url: URL?.none)
        verify(mockMatomoTracker).reset()
        endInteraction(mockMatomoTracker)
    }

    func testScanErrorUnexpectedEventRoutes() {
        let pin = "123456"
        let transportPIN = "123456"
        let store = testStore(setupScanRoutes(pin: pin, transportPIN: transportPIN))
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(5, action: .scan(.error(.init(errorType: .unexpectedEvent(.cardRemoved), retry: true)))))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "cardUnreadable"], url: URL?.none)
        verify(mockMatomoTracker).reset()
        endInteraction(mockMatomoTracker)
    }

    func testScanErrorCardBlockedRoutes() {
        let pin = "123456"
        let transportPIN = "123456"
        let store = testStore(setupScanRoutes(pin: pin, transportPIN: transportPIN))
        store.send(.routeAction(1, action: .setupCoordinator(.routeAction(5, action: .scan(.error(.init(errorType: .cardBlocked, retry: true)))))))
        verify(mockMatomoTracker).track(view: ["firstTimeUser", "cardBlocked"], url: URL?.none)
        verify(mockMatomoTracker).reset()
        endInteraction(mockMatomoTracker)
    }

    func testIdentificationScanSuccessfulRoutes() {
        let pin = "123456"
        let request = AuthenticationRequest.preview
        let certificateDescription = CertificateDescription.preview
        let closure = { (_: FlaggedAttributes) in }
        let pinCallback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let tokenURL = demoTokenURL
        let root = Route<Screen.State>.root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: Coordinator.State(routes: [root], remoteConfiguration: .init(finished: true)),
                              reducer: Coordinator())
        store.exhaustivity = .off
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.uuid = .incrementing
        store.dependencies.urlOpener = urlOpener
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        store.send(.onAppear)

        verify(mockMatomoTracker).reset()
        verify(mockMatomoTracker).track(view: [], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.openURL(tokenURL))

        store.send(.routeAction(1, action: .identificationCoordinator(.eIDInteractionEvent(.success(.authenticationRequestConfirmationRequested(request))))))
        
        verify(mockEIDInteractionManager).retrieveCertificateDescription()
        
        store.send(.routeAction(1, action: .identificationCoordinator(.eIDInteractionEvent(.success(.certificateDescriptionRetrieved(certificateDescription))))))

        verify(mockMatomoTracker).track(view: ["identification", "attributes"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        let authenticationInformation = AuthenticationInformation.preview
        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(0, action: .overview(.loaded(.confirm(authenticationInformation)))))))
        verify(mockMatomoTracker).track(view: ["identification", "personalPIN"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(1, action: .personalPIN(.done(authenticationInformation: authenticationInformation,
                                                                                                                 pin: pin))))))
        verify(mockMatomoTracker).track(view: ["identification", "scan"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(2, action: .scan(.identifiedSuccessfully(redirectURL: tokenURL))))))
        verify(mockMatomoTracker)
            .track(eventWithCategory: "identification",
                   action: "success",
                   name: String?.none,
                   value: Float?.none,
                   dimensions: [],
                   url: URL?.none)
        verify(mockMatomoTracker).track(view: [], url: URL?.none)
        endInteraction(mockMatomoTracker)
    }

    func testIdentificationWrongPINRoutes() {
        let pin = "123456"
        let request = AuthenticationRequest.preview
        let certificate = CertificateDescription.preview
        let authenticationInformation = AuthenticationInformation(request: request, certificateDescription: certificate)
        let tokenURL = demoTokenURL
        let root = Route<Screen.State>.root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let store = TestStore(initialState: Coordinator.State(routes: [root], remoteConfiguration: .init(finished: true)),
                              reducer: Coordinator())
        store.exhaustivity = .off
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.uuid = .incrementing
        store.dependencies.urlOpener = urlOpener
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager
        store.send(.onAppear)

        verify(mockMatomoTracker).reset()
        verify(mockMatomoTracker).track(view: [], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.openURL(tokenURL))

        store.send(.routeAction(1, action: .identificationCoordinator(.eIDInteractionEvent(.success(.authenticationRequestConfirmationRequested(request))))))
        
        store.send(.routeAction(1, action: .identificationCoordinator(.eIDInteractionEvent(.success(.certificateDescriptionRetrieved(certificate))))))
        
        verify(mockMatomoTracker).track(view: ["identification", "attributes"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(0, action: .overview(.loaded(.confirm(authenticationInformation)))))))
        verify(mockMatomoTracker).track(view: ["identification", "personalPIN"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(1, action: .personalPIN(.done(authenticationInformation: authenticationInformation,
                                                                                                                 pin: pin))))))
        verify(mockMatomoTracker).track(view: ["identification", "scan"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(2, action: .scan(.wrongPIN(remainingAttempts: 2))))))
        verify(mockMatomoTracker).track(view: ["identification", "incorrectPersonalPIN"], url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(3, action: .incorrectPersonalPIN(.done(pin: pin))))))
        verify(mockMatomoTracker).track(view: ["identification", "scan"],
                                        url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(2, action: .scan(.requestCAN(authenticationInformation))))))
        verify(mockMatomoTracker).track(view: ["identification", "canPINForgotten"],
                                        url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(3, action: .identificationCANCoordinator(.routeAction(0, action: .canPINForgotten(.orderNewPIN)))))))
        verify(mockMatomoTracker).track(view: ["identification", "canOrderNewPIN"],
                                        url: URL?.none)
        endInteraction(mockMatomoTracker)
    }

    func testIdentificationCANRoutes() {
        let pin = "123456"
        let can = "123456"
        let authenticationInformation = AuthenticationInformation.preview
        let closure = { (_: FlaggedAttributes) in }
        let callback = IdentifiableCallback<FlaggedAttributes>(id: UUID(number: 0), callback: closure)
        let pinCallback = PINCallback(id: UUID(number: 0), callback: { _ in })
        let pinCANCallback = PINCANCallback(id: UUID(number: 0), callback: { _, _ in })
        let tokenURL = URL(string: "https://example.com")!
        let initialCanRoutes: [Route<IdentificationCANScreen.State>] = [.root(.canPINForgotten(.init()))]

        let initialIdentificationRoutes: [Route<IdentificationScreen.State>] = [
            .root(.overview(.loaded(.init(id: UUID(number: 0),
                                          authenticationInformation: authenticationInformation)))),
            .push(.personalPIN(.init(authenticationInformation: authenticationInformation))),
            .push(.scan(.init(authenticationInformation: authenticationInformation, pin: pin))),
            .push(.identificationCANCoordinator(.init(authenticationInformation: authenticationInformation, tokenURL: tokenURL, attempt: 0, states: initialCanRoutes))),
        ]

        let initialRoutes: [Route<Screen.State>] = [
            .root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1))),
            .push(.identificationCoordinator(.init(tokenURL: tokenURL, states: initialIdentificationRoutes))),
        ]

        let store = TestStore(initialState: Coordinator.State(routes: initialRoutes), reducer: Coordinator())
        store.exhaustivity = .off
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.uuid = .incrementing
        store.dependencies.urlOpener = urlOpener
        store.dependencies.eIDInteractionManager = mockEIDInteractionManager

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(3, action: .identificationCANCoordinator(.routeAction(0, action: .canPINForgotten(.showCANIntro)))))))
        verify(mockMatomoTracker).track(view: ["identification", "canIntro"],
                                        url: URL?.none)
        verify(mockMatomoTracker).reset()
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(3, action: .identificationCANCoordinator(.routeAction(1, action: .canIntro(.showInput(shouldDismiss: true))))))))
        verify(mockMatomoTracker).track(view: ["identification", "canInput"],
                                        url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(3, action: .identificationCANCoordinator(.routeAction(2, action: .canInput(.done(can: can, pushesToPINEntry: true))))))))
        verify(mockMatomoTracker).track(view: ["identification", "canPersonalPINInput"],
                                        url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(3, action: .identificationCANCoordinator(.routeAction(3, action: .canPersonalPINInput(.done(pin: pin))))))))
        verify(mockMatomoTracker).track(view: ["identification", "canScan"],
                                        url: URL?.none)
        endInteraction(mockMatomoTracker)

        store.send(.routeAction(1, action: .identificationCoordinator(.routeAction(3, action: .identificationCANCoordinator(.routeAction(4, action: .canScan(.scanEvent(.success(.canRequested)))))))))
        verify(mockMatomoTracker).track(view: ["identification", "canIncorrectInput"],
                                        url: URL?.none)
        endInteraction(mockMatomoTracker)
    }

    private func endInteraction(_ mockMatomoTracker: MockMatomoTrackerProtocol, file: StaticString = #filePath, line: UInt = #line) {
        verifyNoMoreInteractions(mockMatomoTracker, file: file, line: line)
        clearInvocations(mockMatomoTracker)
    }

    private func setupScanRoutes(pin: String, transportPIN: String) -> [Route<Screen.State>] {
        let root = Route<Screen.State>.root(.home(Home.State(appVersion: "1.0.0", buildNumber: 1)))
        let states: [Route<Screen.State>] = [root, .sheet(.setupCoordinator(.init(transportPIN: transportPIN, states: [
            .root(.intro(.init())),
            .push(.transportPINIntro),
            .push(.transportPIN(.init())),
            .push(.personalPINIntro),
            .push(.personalPINInput(.init())),
            .push(.scan(.init(transportPIN: transportPIN, newPIN: pin))),
        ])))]
        return states
    }

    private func testStore(_ initialRoutes: [Route<Screen.State>]) -> TestStore<Coordinator.State, Coordinator.Action, Coordinator.State, Coordinator.Action, Void> {
        let store = TestStore(initialState: Coordinator.State(routes: initialRoutes),
                              reducer: Coordinator())
        store.exhaustivity = .off
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.storageManager = mockStorageManager
        return store
    }
}
