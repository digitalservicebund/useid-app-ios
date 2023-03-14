import XCTest
import ComposableArchitecture
import Analytics
import Cuckoo
@testable import BundesIdent

@MainActor
class RemoteConfigurationTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var mockABTester: MockABTester!

    override func setUp() {
        scheduler = DispatchQueue.test
        mockABTester = MockABTester()
        stub(mockABTester) {
            when($0.prepare()).thenDoNothing()
        }
    }

    func testStartTriggersPrepareABTesterAndStartTimeoutTimer() async {
        let store = TestStore(
            initialState: RemoteConfiguration.State(),
            reducer: RemoteConfiguration()
        )
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.abTester = mockABTester

        await store.send(.start)
        await scheduler.advance()
        await store.receive(.abTesterConfigured) {
            $0.abTesterConfigured = true
        }
        await store.receive(.done) {
            $0.finished = true
        }
        await store.finish()
    }
}
