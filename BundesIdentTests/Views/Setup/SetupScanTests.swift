import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import Analytics

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
            $0.shared.startOnAppear = true
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
        
        let requestChangedPINExpectation = expectation(description: "requestCardInsertion callback")
        let pinCallback: (String, String) -> Void = { actualOldPIN, actualNewPIN in
            XCTAssertEqual(oldPIN, actualOldPIN)
            XCTAssertEqual(newPIN, actualNewPIN)
            requestChangedPINExpectation.fulfill()
        }
        
        store.send(.scanEvent(.success(.authenticationStarted)))
        store.send(.scanEvent(.success(.cardInsertionRequested)))

        store.send(.scanEvent(.success(.cardRecognized))) {
            $0.shared.cardRecognized = true
        }
        
        store.send(.scanEvent(.success(.pinRequested(remainingAttempts: 3)))) {
            $0.remainingAttempts = 3
        }

        store.send(.scanEvent(.success(.cardInsertionRequested))) {
            $0.shared.cardRecognized = false
        }
        store.send(.scanEvent(.success(.cardRecognized))) {
            $0.shared.cardRecognized = true
        }
        store.send(.scanEvent(.success(.pinChangeSucceeded)))

        store.receive(.scannedSuccessfully)

        verify(mockStorageManager).setupCompleted.set(true)

        wait(for: [requestChangedPINExpectation], timeout: 0.0)
    }
    
    func testScanFail() throws {
        let store = TestStore(initialState: SetupScan.State(transportPIN: "12345",
                                                            newPIN: "123456",
                                                            shared: SharedScan.State()),
                              reducer: SetupScan())
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.issueTracker = mockIssueTracker
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        
        let queue = scheduler!
        stub(mockIDInteractionManager) { mock in
            mock.changePIN(messages: any()).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                queue.schedule {
                    subject.send(completion: .failure(.frameworkError(message: "Fail")))
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.scanEvent(.failure(.frameworkError(message: "Fail"))))
        
        store.receive(.error(ScanError.State(errorType: .idCardInteraction(.frameworkError(message: "Fail")), retry: true)))
    }
}
