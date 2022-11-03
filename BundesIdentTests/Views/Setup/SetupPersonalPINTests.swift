import XCTest
import ComposableArchitecture
import Cuckoo
import Analytics

@testable import BundesIdent

class SetupPersonalPINViewModelTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    var mockAnalyticsClient: MockAnalyticsClient!
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        environment = AppEnvironment.mocked(mainQueue: scheduler.eraseToAnyScheduler(), analytics: mockAnalyticsClient)
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }
    
    func testCompletePIN1() throws {
        let store = TestStore(initialState: SetupPersonalPINInputState(enteredPIN: "12345"),
                              reducer: setupPersonalPINInputReducer,
                              environment: environment)
        
        store.send(.binding(.set(\.$enteredPIN, "123456"))) { state in
            state.enteredPIN = "123456"
        }
    }
    
    func testCorrectPIN2() throws {
        let store = TestStore(initialState: SetupPersonalPINConfirmState(enteredPIN1: "123456",
                                                                  enteredPIN2: "12345"),
                              reducer: setupPersonalPINConfirmReducer,
                              environment: environment)
        store.send(.binding(.set(\.$enteredPIN2, "123456"))) { state in
            state.enteredPIN2 = "123456"
        }
    }
    
    func testMismatchingPIN2() throws {
        let store = TestStore(initialState: SetupPersonalPINConfirmState(enteredPIN1: "123456",
                                                                  enteredPIN2: "98765"),
                              reducer: setupPersonalPINConfirmReducer,
                              environment: environment)
        store.send(.binding(.set(\.$enteredPIN2, "987654"))) { state in
            state.enteredPIN2 = "987654"
        }
        store.receive(.mismatchError) { state in
            state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title),
                                     message: nil,
                                     buttons: [.default(TextState(L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.retry), action: .send(.confirmMismatch))])
        }
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "errorShown",
                                                                name: "personalPINMismatch"))
    }
}
