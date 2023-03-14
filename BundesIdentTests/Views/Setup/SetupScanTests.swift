import Analytics
import Combine
import ComposableArchitecture
import Cuckoo
import XCTest

@testable import BundesIdent

class SetupScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    var mockIssueTracker: MockIssueTracker!
    var mockStorageManager: MockStorageManagerType!
    var mockIDInteractionManager: MockIDInteractionManagerType!
    var mockPreviewIDInteractionManager: MockPreviewIDInteractionManagerType!
    
    override func setUp() {
        mockAnalyticsClient = MockAnalyticsClient()
        mockIssueTracker = MockIssueTracker()
        scheduler = DispatchQueue.test
        mockStorageManager = MockStorageManagerType()
        mockIDInteractionManager = MockIDInteractionManagerType()
        mockPreviewIDInteractionManager = MockPreviewIDInteractionManagerType()
        
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
        
        stub(mockPreviewIDInteractionManager) {
            $0.isDebugModeEnabled.get.thenReturn(false)
        }
    }
    
    func testInitiateScan() throws {
        let oldPIN = "12345"
        let newPIN = "123456"
        let store = TestStore(initialState: SetupScan.State(transportPIN: oldPIN, newPIN: newPIN),
                              reducer: SetupScan())
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.storageManager = mockStorageManager
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
            $0.shared.showInstructions = false
        }
        
        store.receive(.shared(.initiateScan))
    }
    
    func testChangePINSuccess() throws {
        let oldPIN = "12345"
        let newPIN = "123456"
        let store = TestStore(initialState: SetupScan.State(transportPIN: oldPIN, newPIN: newPIN),
                              reducer: SetupScan())
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        
        let cardInsertionCallback: (String) -> Void = { _ in }
        
        let requestChangedPINExpectation = expectation(description: "requestCardInsertion callback")
        let pinCallback: (String, String) -> Void = { actualOldPIN, actualNewPIN in
            XCTAssertEqual(oldPIN, actualOldPIN)
            XCTAssertEqual(newPIN, actualNewPIN)
            requestChangedPINExpectation.fulfill()
        }
        
        store.send(.scanEvent(.success(.authenticationStarted))) {
            $0.shared.isScanning = true
        }
        store.send(.scanEvent(.success(.requestCardInsertion(cardInsertionCallback))))

        store.send(.scanEvent(.success(.cardRecognized))) {
            $0.shared.cardRecognized = true
        }
        
        store.send(.scanEvent(.success(.cardInteractionComplete)))
        store.send(.scanEvent(.success(.requestChangedPIN(remainingAttempts: 3, pinCallback: pinCallback)))) {
            $0.remainingAttempts = 3
        }

        store.send(.scanEvent(.success(.cardRemoved))) {
            $0.shared.showProgressCaption = ProgressCaption(title: L10n.FirstTimeUser.Scan.Progress.title,
                                                            body: L10n.FirstTimeUser.Scan.Progress.body)
        }
        store.send(.scanEvent(.success(.requestCardInsertion(cardInsertionCallback)))) {
            $0.shared.showProgressCaption = nil
            $0.shared.cardRecognized = false
        }
        store.send(.scanEvent(.success(.cardRecognized))) {
            $0.shared.cardRecognized = true
        }
        store.send(.scanEvent(.success(.cardInteractionComplete)))
        store.send(.scanEvent(.success(.processCompletedSuccessfullyWithoutRedirect)))

        store.receive(.scannedSuccessfully)

        verify(mockStorageManager).setupCompleted.set(true)

        wait(for: [requestChangedPINExpectation], timeout: 0.0)
    }
    
    func testScanFail() throws {
        let store = TestStore(initialState: SetupScan.State(transportPIN: "12345",
                                                            newPIN: "123456",
                                                            shared: SharedScan.State(isScanning: true)),
                              reducer: SetupScan())
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        
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
        
        store.send(.scanEvent(.failure(.frameworkError(message: "Fail")))) {
            $0.shared.isScanning = false
        }
        
        store.receive(.error(ScanError.State(errorType: .idCardInteraction(.frameworkError(message: "Fail")), retry: true)))
    }
    
    func testShowNFCInfo() {
        let store = TestStore(initialState: SetupScan.State(transportPIN: "12345", newPIN: "123456"),
                              reducer: SetupScan())
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
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
}
