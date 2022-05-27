import SwiftUI
import TCACoordinators
import ComposableArchitecture

@main
struct BundIDApp: App {
    
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        store = Store(
            initialState: CoordinatorState(routes: [.root(.home, embedInNavigationView: true)]),
            reducer: coordinatorReducer,
            environment: AppEnvironment(
                mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                idInteractionManager: IDInteractionManager()
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView(store: store)
        }
    }
}
