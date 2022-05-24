import SwiftUI
import TCACoordinators
import ComposableArchitecture

@main
struct BundIDApp: App {
    var body: some Scene {
        WindowGroup {
            CoordinatorView(store: Store(
                initialState: CoordinatorState(routes: [.root(.home, embedInNavigationView: true)]),
                reducer: coordinatorReducer,
                environment: .init(mainQueue: DispatchQueue.main.eraseToAnyScheduler())
            ))
        }
    }
}
