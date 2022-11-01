import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

class SetupScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockIssueTracker: MockIssueTracker!
    var mockStorageManager: MockStorageManagerType!
    var mockIDInteractionManager: MockIDInteractionManagerType!
    
    override func setUp() {
        mockAnalyticsClient = MockAnalyticsClient()
        mockIssueTracker = MockIssueTracker()
        scheduler = DispatchQueue.test
        mockStorageManager = MockStorageManagerType()
        mockIDInteractionManager = MockIDInteractionManagerType()
        environment = AppEnvironment.mocked(mainQueue: scheduler.eraseToAnyScheduler(),
                                            idInteractionManager: mockIDInteractionManager,
                                            storageManager: mockStorageManager,
                                            analytics: mockAnalyticsClient,
                                            issueTracker: mockIssueTracker)
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
        
        stub(mockIssueTracker) {
            $0.addBreadcrumb(crumb: any()).thenDoNothing()
            $0.capture(error: any()).thenDoNothing()
        }
        
        stub(mockStorageManager) {
            when($0.setupCompleted.set(true)).thenDoNothing()
        }
    }
    
    func testChangePINSuccess() throws {
        let oldPIN = "12345"
        let newPIN = "123456"
        let store = TestStore(initialState: SetupScanState(transportPIN: oldPIN, newPIN: newPIN),
                              reducer: setupScanReducer,
                              environment: environment)
        
        let cardInsertionCallback: (String) -> Void = { _ in }
        
        let requestChangedPINExpectation = self.expectation(description: "requestCardInsertion callback")
        let pinCallback: (String, String) -> Void = { actualOldPIN, actualNewPIN in
            XCTAssertEqual(oldPIN, actualOldPIN)
            XCTAssertEqual(newPIN, actualNewPIN)
            requestChangedPINExpectation.fulfill()
        }
        
        let queue = scheduler!
        stub(mockIDInteractionManager) { mock in
            mock.changePIN(nfcMessagesProvider: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                queue.schedule {
                    subject.send(.authenticationStarted)
                    subject.send(.requestCardInsertion(cardInsertionCallback))
                    subject.send(.cardRecognized)
                    subject.send(.cardInteractionComplete)
                    subject.send(.requestChangedPIN(remainingAttempts: 3, pinCallback: pinCallback))
                    subject.send(.cardRemoved)
                    subject.send(.requestCardInsertion(cardInsertionCallback))
                    subject.send(.cardRecognized)
                    subject.send(.cardInteractionComplete)
                    subject.send(.processCompletedSuccessfullyWithoutRedirect)
                    subject.send(completion: .finished)
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        scheduler.advance()
        
        store.receive(.scanEvent(.success(.authenticationStarted)))
        store.receive(.scanEvent(.success(.requestCardInsertion(cardInsertionCallback))))
        
        store.receive(.scanEvent(.success(.cardRecognized)))
        store.receive(.scanEvent(.success(.cardInteractionComplete)))
        store.receive(.scanEvent(.success(.requestChangedPIN(remainingAttempts: 3, pinCallback: pinCallback)))) {
            $0.remainingAttempts = 3
        }
        
        store.receive(.scanEvent(.success(.cardRemoved))) {
            $0.shared.showProgressCaption = ProgressCaption(title: L10n.FirstTimeUser.Scan.Progress.title,
                                                            body: L10n.FirstTimeUser.Scan.Progress.body)
        }
        store.receive(.scanEvent(.success(.requestCardInsertion(cardInsertionCallback)))) {
            $0.shared.showProgressCaption = nil
        }
        store.receive(.scanEvent(.success(.cardRecognized)))
        store.receive(.scanEvent(.success(.cardInteractionComplete)))
        store.receive(.scanEvent(.success(.processCompletedSuccessfullyWithoutRedirect)))
        
        store.receive(.scannedSuccessfully)
        
        verify(mockStorageManager).setupCompleted.set(true)
        
        self.wait(for: [requestChangedPINExpectation], timeout: 0.0)
    }
    
    func testScanFail() throws {
        let store = TestStore(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"),
                              reducer: setupScanReducer,
                              environment: environment)
        
        let queue = scheduler!
        stub(mockIDInteractionManager) { mock in
            mock.changePIN(nfcMessagesProvider: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                queue.schedule {
                    subject.send(completion: .failure(.frameworkError(message: "Fail")))
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        scheduler.advance()
        
        store.receive(.scanEvent(.failure(.frameworkError(message: "Fail")))) {
            $0.shared.isScanning = false
        }
        
        store.receive(.error(ScanErrorState(errorType: .idCardInteraction(.frameworkError(message: "Fail")), retry: true)))
    }
    
    func testShowNFCInfo() {
        let store = TestStore(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"),
                              reducer: setupScanReducer,
                              environment: environment)
        
        store.send(.shared(.showNFCInfo)) {
            $0.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                  message: TextState(L10n.HelpNFC.body),
                                  dismissButton: .cancel(TextState(L10n.General.ok),
                                                         action: .send(.dismissAlert)))
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "alertShown",
                                                                name: "NFCInfo"))
    }
    
    func testStartScanTracking() {
        let store = TestStore(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"),
                              reducer: setupScanReducer,
                              environment: environment)
        
        stub(mockIDInteractionManager) { mock in
            mock.changePIN(nfcMessagesProvider: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                self.scheduler.schedule {
                    subject.send(completion: .finished)
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        scheduler.advance()
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "buttonPressed",
                                                                name: "scan"))
    }
}
