import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard

@main
struct BundIDApp: App {
    
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        
#if MOCK_OPENECARD
        let idInteractionManager = DebugIDInteractionManager()
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp(),
                                                        nfcMessageProvider: NFCMessageProvider())
#endif

        store = Store(
            initialState: CoordinatorState(states: [.root(.home(HomeState()), embedInNavigationView: true)]),
            reducer: coordinatorReducer,
            environment: AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager
            )
        )
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
