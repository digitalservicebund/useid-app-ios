import Analytics
import XCTest
import ComposableArchitecture
import Cuckoo
import Combine
import TCACoordinators

@testable import BundID

final class IdentificationOverviewTests: XCTestCase {
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

    func testLoadingFailure() {
        let error = IdentifiableError(NSError(domain: "", code: 0))
        let store = TestStore(
            initialState: IdentificationOverviewState.loading(.init()),
            reducer: identificationOverviewReducer,
            environment: environment
        )
        
        store.send(IdentificationOverviewAction.loading(.failure(error))) {
            $0 = .error(error)
        }
        
        verify(mockAnalyticsClient).track(event: AnalyticsEvent(category: "identification",
                                                                action: "loadingFailed",
                                                                name: "attributes"))
    }
}
