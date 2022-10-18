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
        let store = TestStore(initialState: SetupPersonalPINState(enteredPIN1: "12345"),
                              reducer: setupPersonalPINReducer,
                              environment: environment)
        
        store.send(.binding(.set(\.$enteredPIN1, "123456"))) { state in
            state.enteredPIN1 = "123456"
            state.showPIN2 = true
            state.focusedField = .pin2
        }
    }
    
    func testCorrectPIN2() throws {
        let store = TestStore(initialState: SetupPersonalPINState(enteredPIN1: "123456",
                                                                  enteredPIN2: "12345",
                                                                  showPIN2: true),
                              reducer: setupPersonalPINReducer,
                              environment: environment)
        store.send(.binding(.set(\.$enteredPIN2, "123456"))) { state in
            state.enteredPIN2 = "123456"
        }
    }
    
    func testMismatchingPIN2() throws {
        let store = TestStore(initialState: SetupPersonalPINState(enteredPIN1: "123456",
                                                                  enteredPIN2: "98765",
                                                                  showPIN2: true),
                              reducer: setupPersonalPINReducer,
                              environment: environment)
        store.send(.binding(.set(\.$enteredPIN2, "987654"))) { state in
            state.enteredPIN2 = "987654"
            state.remainingAttempts = 1
        }
        
        scheduler.advance(by: 0.2)
        
        store.receive(.reset) { state in
            state.error = .mismatch
            state.showPIN2 = false
            state.enteredPIN2 = ""
            state.enteredPIN1 = ""
            state.focusedField = .pin1
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "errorShown",
                                                                name: "personalPINMismatch"))
    }
    
    func testTypingWhileShowingError() throws {
        let store = TestStore(initialState: SetupPersonalPINState(enteredPIN1: "",
                                                                  error: .mismatch),
                              reducer: setupPersonalPINReducer,
                              environment: environment)
        store.send(.binding(.set(\.$enteredPIN1, "1"))) { state in
            state.enteredPIN1 = "1"
            state.error = nil
        }
    }
    
    func testOnAppear() throws {
        let store = TestStore(initialState: SetupPersonalPINState(),
                              reducer: setupPersonalPINReducer,
                              environment: environment)
        
        store.send(.onAppear)
        
        scheduler.advance(by: 1)
        
        store.receive(.focus(.pin1)) { state in
            state.focusedField = .pin1
        }
    }
}