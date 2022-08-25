import XCTest
import ComposableArchitecture
import Cuckoo
import Combine

@testable import BundID

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
                                     debugIDInteractionManager: DebugIDInteractionManager())
    }
    
    func testEndTriggersConfirmation() {
        let store = TestStore(
            initialState: SetupCoordinatorState(states: [ .root(.intro) ]),
            reducer: setupCoordinatorReducer,
            environment: environment
        )
        
        store.send(.end) {
            $0.alert = AlertState(title: .init(verbatim: L10n.FirstTimeUser.ConfirmEnd.title), message: .init(verbatim: L10n.FirstTimeUser.ConfirmEnd.message), primaryButton: .destructive(.init(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm), action: .send(.confirmEnd)), secondaryButton: .cancel(.init(verbatim: L10n.General.cancel)))
        }
    }
    
    func testMissingPINLetterNavigation() {
            let store = TestStore(initialState: SetupCoordinatorState(states: [.root(.intro), .push(.transportPINIntro)]),
                                  reducer: setupCoordinatorReducer,
                                  environment: environment)
            
            store.send(.routeAction(0, action: .transportPINIntro(.missingPINLetter))) {
                $0.routes = [.root(.intro), .push(.transportPINIntro), .push(.missingPINLetter)]
            }
        }
}
