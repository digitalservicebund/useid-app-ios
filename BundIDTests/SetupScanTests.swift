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
        environment = AppEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                     idInteractionManager: mockIDInteractionManager)
    }
    
    func testStartScan() throws {
        let store = TestStore(initialState: SetupScanState(),
                              reducer: setupScanReducer,
                              environment: environment)
        
        let queue = scheduler!
        stub(mockIDInteractionManager) { mock in
            mock.changePIN().then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                queue.schedule {
                    subject.send(.authenticationStarted)
                }
                queue.schedule(after: queue.now.advanced(by: .seconds(1))) {
                    subject.send(.authenticationSuccessful)
                    subject.send(completion: .finished)
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.startScan)
        
        scheduler.advance()
        
        store.receive(.scanEvent(.success(.authenticationStarted)))
        
        scheduler.advance(by: .seconds(1))
        
        store.receive(.scanEvent(.success(.authenticationSuccessful)))
    }
    
    func testScanFail() throws {
        let store = TestStore(initialState: SetupScanState(),
                              reducer: setupScanReducer,
                              environment: environment)
        
        let queue = scheduler!
        stub(mockIDInteractionManager) { mock in
            mock.changePIN().then { _ in
                let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
                queue.schedule {
                    subject.send(completion: .failure(.frameworkError(message: "Fail")))
                }
                return subject.eraseToAnyPublisher()
            }
        }
        
        store.send(.startScan)
        
        scheduler.advance()
        
        store.receive(.scanEvent(.failure(.frameworkError(message: "Fail")))) {
            $0.error = .idCardInteraction(.frameworkError(message: "Fail"))
        }
    }
}
