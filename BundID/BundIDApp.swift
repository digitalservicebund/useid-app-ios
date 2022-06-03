import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard

@main
struct BundIDApp: App {
    
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        store = Store(
            initialState: CoordinatorState(routes: [.root(.home, embedInNavigationView: true)]),
            reducer: coordinatorReducer,
            environment: AppEnvironment(
                mainQueue: mainQueue,
                idInteractionManager: IDInteractionManager(openEcard: OpenEcardImp(),
                                                           nfcMessageProvider: NFCMessageProvider())
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView(store: store)
        }
    }
}
