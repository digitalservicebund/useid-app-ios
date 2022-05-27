import XCTest
import ComposableArchitecture

@testable import BundID

class SetupScanTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    
    override func setUp() {
        scheduler = DispatchQueue.test
        environment = AppEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                     idInteractionManager: MockIDInteractionManager(queue: scheduler.eraseToAnyScheduler()))
    }
    
    func testStartScan() throws {
        let store = TestStore(initialState: SetupScanState(),
                              reducer: setupScanReducer,
                              environment: environment)
        
        store.send(.startScan)
        scheduler.advance()
        
        store.receive(.scanEvent(.success(.authenticationStarted)))
        store.receive(.scanEvent(.failure(.frameworkError(message: "Not implemented"))))
    }
}
