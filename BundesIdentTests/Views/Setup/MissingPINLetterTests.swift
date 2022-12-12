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
    
    override func setUp() {
        scheduler = DispatchQueue.test
        mockAnalyticsClient = MockAnalyticsClient()
        
        stub(mockAnalyticsClient) {
            $0.track(view: any()).thenDoNothing()
            $0.track(event: any()).thenDoNothing()
        }
    }

    func testOpenMissingPINLetterEvent() {
        let store = TestStore(
            initialState: MissingPINLetter.State(),
            reducer: MissingPINLetter()
        )
        store.dependencies.analytics = mockAnalyticsClient
        store.send(.openExternalLink)
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "firstTimeUser",
                                                                action: "externalLinkOpened",
                                                                name: "PINLetter"))
    }
}
