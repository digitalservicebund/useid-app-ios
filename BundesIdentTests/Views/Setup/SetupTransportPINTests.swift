import XCTest
import ComposableArchitecture
import Cuckoo
import Analytics

@testable import BundesIdent

class SetupTransportPINViewModelTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    
    override func setUp() {
        scheduler = DispatchQueue.test
    }
    
    func testCompletePIN() throws {
        let store = TestStore(
          initialState: SetupTransportPIN.State(enteredPIN: ""),
          reducer: SetupTransportPIN()
        )
        
        store.send(.binding(.set(\.$enteredPIN, "12345"))) { state in
            state.enteredPIN = "12345"
        }
    }
}
