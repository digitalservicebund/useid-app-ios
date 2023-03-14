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
    }

    func testStartTriggersFlowWithABTesterRespondingBeforeTimeout() async {
        let store = TestStore(
            initialState: RemoteConfiguration.State(),
            reducer: RemoteConfiguration()
        )
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.abTester = mockABTester
        stub(mockABTester) {
            when($0.prepare()).thenDoNothing()
        }

        await store.send(.start)
        await store.receive(.abTesterConfigured) {
            $0.abTesterConfigured = true
            $0.finished = true
        }
        await store.receive(.done)
    }

    func testStartTriggersFlowWithABTesterRespondingAfterTimeout() async {
        let store = TestStore(
            initialState: RemoteConfiguration.State(),
            reducer: RemoteConfiguration()
        )
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        store.dependencies.abTester = mockABTester
        stub(mockABTester) {
            when($0.prepare()).then {
                DispatchQueue.main.async {
                    self.scheduler.advance(by: 2)
                }
            }
        }
        stub(mockABTester) {
            when($0.disable()).thenDoNothing()
        }

        await store.send(.start)
        await store.receive(.timeout) {
            $0.finished = true
            verify(self.mockABTester).disable()
        }
        await store.receive(.done)
        await store.receive(.abTesterConfigured)
    }
}
