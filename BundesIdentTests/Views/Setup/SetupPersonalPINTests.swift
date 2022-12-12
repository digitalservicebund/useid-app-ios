import XCTest
import ComposableArchitecture
import Cuckoo
import Analytics

@testable import BundesIdent

class SetupPersonalPINViewModelTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }
    
    func testCompletePIN1() throws {
        let store = TestStore(initialState: SetupPersonalPINInput.State(enteredPIN: "12345"),
                              reducer: SetupPersonalPINInput())
        
        store.send(.binding(.set(\.$enteredPIN, "123456"))) { state in
            state.enteredPIN = "123456"
        }
    }
    
    func testCorrectPIN2() throws {
        let store = TestStore(initialState: SetupPersonalPINConfirm.State(enteredPIN1: "123456",
                                                                          enteredPIN2: "12345"),
                              reducer: SetupPersonalPINConfirm())
        store.send(.binding(.set(\.$enteredPIN2, "123456"))) { state in
            state.enteredPIN2 = "123456"
        }
    }
    
    func testMismatchingPIN2() throws {
        let store = TestStore(initialState: SetupPersonalPINConfirm.State(enteredPIN1: "123456",
                                                                          enteredPIN2: "98765"),
                              reducer: SetupPersonalPINConfirm())
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.binding(.set(\.$enteredPIN2, "987654"))) { state in
            state.enteredPIN2 = "987654"
        }
        
        store.send(.checkPINs)
        store.receive(.mismatchError) { state in
            state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title),
                                     message: nil,
                                     buttons: [.default(TextState(L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.retry), action: .send(.confirmMismatch))])
        }
    }
}
