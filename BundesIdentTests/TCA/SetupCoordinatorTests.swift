import XCTest
import ComposableArchitecture
import Cuckoo
import Combine

@testable import BundesIdent

class SetupCoordinatorTests: XCTestCase {
    
    var scheduler: TestSchedulerOf<DispatchQueue>!
    var environment: AppEnvironment!
    var uuidCount = 0
    
    var mockIDInteractionManager = MockIDInteractionManagerType()
    
    func uuidFactory() -> UUID {
        let currentCount = self.uuidCount
        self.uuidCount += 1
        return UUID(number: currentCount)
    }
    
    override func setUp() {
        scheduler = DispatchQueue.test
        environment = AppEnvironment(mainQueue: scheduler.eraseToAnyScheduler(),
                                     uuidFactory: uuidFactory,
                                     idInteractionManager: mockIDInteractionManager,
                                     storageManager: MockStorageManagerType(),
                                     analytics: MockAnalyticsClient(),
                                     urlOpener: { _ in },
                                     issueTracker: MockIssueTracker(),
                                     debugIDInteractionManager: DebugIDInteractionManager())
    }
    
    func testEndTriggersConfirmation() {
        let store = TestStore(
            initialState: SetupCoordinatorState(states: [ .root(.intro(.init(tokenURL: nil))) ]),
            reducer: setupCoordinatorReducer,
            environment: environment
        )
        
        store.send(.end) {
            $0.alert = AlertState(title: .init(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                                  message: .init(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                                  primaryButton: .destructive(.init(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm), action: .send(.confirmEnd)),
                                  secondaryButton: .cancel(.init(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
        }
    }
    
    func testMissingPINLetterNavigation() {
        let store = TestStore(initialState: SetupCoordinatorState(states: [.root(.intro(.init(tokenURL: nil))), .push(.transportPINIntro)]),
                              reducer: setupCoordinatorReducer,
                              environment: environment)
        
        store.send(.routeAction(0, action: .transportPINIntro(.choosePINLetterMissing))) {
            $0.routes = [.root(.intro(.init(tokenURL: nil))), .push(.transportPINIntro), .push(.missingPINLetter(.init()))]
        }
    }
}
