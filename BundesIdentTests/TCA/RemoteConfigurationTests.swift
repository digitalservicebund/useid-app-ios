import XCTest
import ComposableArchitecture
import Analytics
import Cuckoo
@testable import BundesIdent

@MainActor
class RemoteConfigurationTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockABTester: MockABTester!
    var mockPreviewIDInteractionManager: MockPreviewIDInteractionManagerType!

    override func setUp() {
        mockPreviewIDInteractionManager = MockPreviewIDInteractionManagerType()
        scheduler = DispatchQueue.test
        mockABTester = MockABTester()
        stub(mockABTester) {
            when($0.prepare()).thenDoNothing()
        }
    }

    func testStartTriggersPrepareABTesterAndStartTimeoutTimer() async {
        let store = TestStore(
            initialState: RemoteConfiguration.State(),
            reducer: RemoteConfiguration()//.dependency(\.abTester, mockABTester)
        )
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.abTester = mockABTester
        store.dependencies.previewIDInteractionManager = mockPreviewIDInteractionManager

        await store.send(.start)
        await store.receive(.prepareABTester)
        await store.receive(.startTimeoutTimer)
        await store.receive(.abTesterConfigured) {
            $0.abTesterConfigured = true
            verify(self.mockABTester).disable()
        }
        await store.receive(.stopTimoutTimer)
        await store.receive(.done)
    }
}
