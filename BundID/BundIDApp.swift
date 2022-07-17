import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard

@main
struct BundIDApp: App {
    
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        
#if PREVIEW
        let idInteractionManager = DebugIDInteractionManager()
        
        store = Store(
            initialState: CoordinatorState(states: [.root(.home(HomeState()), embedInNavigationView: true)]),
            reducer: coordinatorReducer,
            environment: AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                debugIDInteractionManager: idInteractionManager
            )
        )
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp(),
                                                        nfcMessageProvider: NFCMessageProvider())
        
        store = Store(
            initialState: CoordinatorState(states: [.root(.home(HomeState()), embedInNavigationView: true)]),
            reducer: coordinatorReducer,
            environment: AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager
            )
        )
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            WithViewStore(store.stateless) { viewStore in
                CoordinatorView(store: store)
                    .onOpenURL { url in
                        viewStore.send(.openURL(url))
                    }
            }
        }
    }
}
