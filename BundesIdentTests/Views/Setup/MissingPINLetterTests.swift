import Analytics
import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundesIdent

class MissingPINLetterTests: XCTestCase {
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockAnalyticsClient: MockAnalyticsClient!
    var environment: AppEnvironment!
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        environment = AppEnvironment.mocked(analytics: mockAnalyticsClient)
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }

    func testOpenMissingPINLetterEvent() {
        let store = TestStore(
            initialState: MissingPINLetterState(),
            reducer: missingPINLetterReducer,
            environment: environment
        )
        
        store.send(.openExternalLink)
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "externalLinkOpened",
                                                                name: "PINLetter"))
    }
}
