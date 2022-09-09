import Analytics
import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundID

final class IdentificationDoneTests: XCTestCase {
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
    
    func testContinueToServiceEvent() {
        let redirectUrl = URL(string: "localhost")!
        
        let store = TestStore(
            initialState: IdentificationDoneState(request: .preview, redirectURL: redirectUrl.absoluteString),
            reducer: identificationDoneReducer,
            environment: environment
        )
        
        store.send(IdentificationDoneAction.openURL(redirectUrl))
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "buttonPressed",
                                                                name: "continueToService"))
    }
    
}
