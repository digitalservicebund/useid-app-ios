import XCTest
import ComposableArchitecture
import TCACoordinators
import Cuckoo
import Combine
import Analytics

@testable import BundesIdent

class SetupCANScanTests: XCTestCase {
    
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
        
        stub(mockIDInteractionManager) {
            $0.setCAN(any()).thenDoNothing()
            $0.setPIN(any()).thenDoNothing()
        }
    }
    
    override func tearDown() {
        verifyNoMoreInteractions(mockIDInteractionManager)
    }
    
    func testStartScan() throws {
        let oldPIN = "12345"
        let newPIN = "123456"
        let can = "111111"
        let store = TestStore(initialState: SetupCANScan.State(transportPIN: oldPIN, newPIN: newPIN, can: can),
                              reducer: SetupCANScan())
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.idInteractionManager = mockIDInteractionManager
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
        }
        
        verify(mockIDInteractionManager).setCAN(can)
    }
    
    func testChangePINWithCANSuccess() throws {
        let oldPIN = "12345"
        let newPIN = "123456"
        let can = "111111"
        
        let requestChangedPINExpectation = expectation(description: "requestChangedPINExpectation callback")
        let canAndChangedPINCallback = CANAndChangedPINCallback(id: .zero) {
            XCTAssertEqual($0.can, can)
            XCTAssertEqual($0.oldPIN, oldPIN)
            XCTAssertEqual($0.newPIN, newPIN)
            requestChangedPINExpectation.fulfill()
        }
        
        let store = TestStore(initialState: SetupCANScan.State(transportPIN: oldPIN, newPIN: newPIN, can: can),
                              reducer: SetupCANScan())
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.analytics = mockAnalyticsClient
        store.dependencies.storageManager = mockStorageManager
        store.dependencies.idInteractionManager = mockIDInteractionManager
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager
        
        let cardInsertionCallback: (String) -> Void = { _ in }
        
        store.send(.shared(.startScan)) {
            $0.shared.isScanning = true
        }
        
        store.send(.scanEvent(.success(.authenticationStarted)))
        store.send(.scanEvent(.success(.cardInsertionRequested)))
        
        store.send(.scanEvent(.success(.cardRecognized))) {
            $0.shared.cardRecognized = true
        }
        
        store.send(.scanEvent(.success(.pinChangeSucceeded)))
        
        store.receive(.scannedSuccessfully)
        
        verify(mockStorageManager).setupCompleted.set(true)
        
        wait(for: [requestChangedPINExpectation], timeout: 0.0)
    }
    
    func testScanFail() throws {
        let store = TestStore(initialState: SetupCANScan.State(transportPIN: "12345",
                                                               newPIN: "123456",
                                                               can: "111111",
                                                               shared: SharedScan.State(isScanning: true)),
                              reducer: SetupCANScan())
        
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
        
        store.send(.scanEvent(.failure(.frameworkError(message: "Fail")))) {
            $0.shared.isScanning = false
        }
        
        store.receive(.error(ScanError.State(errorType: .idCardInteraction(.frameworkError(message: "Fail")), retry: true)))
    }
    
    func testShowNFCInfo() {
        let store = TestStore(initialState: SetupCANScan.State(transportPIN: "12345", newPIN: "123456", can: "111111"),
                              reducer: SetupCANScan())
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
        verifyNoMoreInteractions(mockAnalyticsClient)
    }
    
    // TODO: Can we even test this?
//    func testCancellationOfScanOverlay() {
//        let pin = "111111"
//        let transportPIN = "12345"
//        let can = "333333"
//        let canAndChangedPINCallback = CANAndChangedPINCallback(id: UUID(number: 0)) { _ in }
//        let store = TestStore(
//            initialState: SetupCANScan.State(transportPIN: transportPIN,
//                                             newPIN: pin,
//                                             can: can),
//            reducer: SetupCANScan()
//        )
//
//        let pinCallback: (String, String) -> Void = { _, _ in
//            XCTFail("Callback should not be called")
//        }
//
//        // This is the event that gets published when the user waits too long on the scan overlay or when tapping on the cancel button
//        store.send(.scanEvent(.success(.requestChangedPIN(remainingAttempts: nil, pinCallback: pinCallback)))) {
//            $0.shared.isScanning = false
//            $0.canAndChangedPINCallback = nil
//        }
//
//        store.send(.shared(.startScan)) {
//            $0.shared.isScanning = true
//        }
//
//        store.receive(.shared(.initiateScan))
//    }
}
