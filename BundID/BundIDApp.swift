import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard

@main
struct BundIDApp: App {
    
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        
#if targetEnvironment(simulator)
        let idInteractionManager = DebugIDInteractionManager()
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp(),
                                                        nfcMessageProvider: NFCMessageProvider())
#endif

        store = Store(
            initialState: CoordinatorState(routes: [.root(.home, embedInNavigationView: true)]),
            reducer: coordinatorReducer,
            environment: AppEnvironment(
                mainQueue: mainQueue,
                idInteractionManager: idInteractionManager
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView(store: store)
        }
    }
}
