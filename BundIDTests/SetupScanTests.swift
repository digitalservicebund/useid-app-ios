import XCTest
import ComposableArchitecture
import Cuckoo
import Combine

@testable import BundID

class SetupScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    
    var mockIDInteractionManager = MockIDInteractionManagerType()
    
    override func setUp() {
        scheduler = DispatchQueue.test
        environment = AppEnvironment.mocked(mainQueue: scheduler.eraseToAnyScheduler(),
                                            idInteractionManager: mockIDInteractionManager)
    }
    
    func testChangePINSuccess() throws {
        let oldPIN = "12345"
        let newPIN = "123456"
        let store = TestStore(initialState: SetupScanState(transportPIN: oldPIN, newPIN: newPIN),
                              reducer: setupScanReducer,
                              environment: environment)
        
        let cardInsertionExpectation = self.expectation(description: "requestCardInsertion callback")
        cardInsertionExpectation.expectedFulfillmentCount = 2
        
        let cardInsertionCallback: (String) -> Void = { _ in
            cardInsertionExpectation.fulfill()
        }
        
        let requestChangedPINExpectation = self.expectation(description: "requestCardInsertion callback")
        let pinCallback: (String, String) -> Void = { actualOldPIN, actualNewPIN in
            XCTAssertEqual(oldPIN, actualOldPIN)
            XCTAssertEqual(newPIN, actualNewPIN)
            requestChangedPINExpectation.fulfill()
        }
        
        let queue = scheduler!
        stub(mockIDInteractionManager) { mock in
            mock.changePIN(nfcMessages: NFCMessages.setup).then { _ in
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
        
        store.send(.startScan) {
            $0.isScanning = true
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
            $0.showProgressCaption = true
        }
        store.receive(.scanEvent(.success(.requestCardInsertion(cardInsertionCallback)))) {
            $0.showProgressCaption = false
        }
        store.receive(.scanEvent(.success(.cardRecognized)))
        store.receive(.scanEvent(.success(.cardInteractionComplete)))
        store.receive(.scanEvent(.success(.processCompletedSuccessfullyWithoutRedirect)))
        
        store.receive(.scannedSuccessfully)
        
        self.wait(for: [cardInsertionExpectation, requestChangedPINExpectation], timeout: 0.0)
    }
    
    func testScanFail() throws {
        let store = TestStore(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"),
                              reducer: setupScanReducer,
                              environment: environment)
        
        let queue = scheduler!
        stub(mockIDInteractionManager) { mock in
            mock.changePIN(nfcMessages: NFCMessages.setup).then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                queue.schedule {
                    subject.send(completion: .failure(.frameworkError(message: "Fail")))
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.startScan) {
            $0.isScanning = true
        }
        
        scheduler.advance()
        
        store.receive(.scanEvent(.failure(.frameworkError(message: "Fail")))) {
            $0.isScanning = false
        }
        
        store.receive(.error(ScanErrorState(errorType: .idCardInteraction(.frameworkError(message: "Fail")), retry: true)))
    }
}
