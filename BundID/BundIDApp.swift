import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard

@main
struct BundIDApp: App {
    
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        let environment: AppEnvironment
#if PREVIEW
        if MOCK_OPENECARD {
            let idInteractionManager = DebugIDInteractionManager()
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                debugIDInteractionManager: idInteractionManager
            )
        } else {
            let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp(),
                                                            nfcMessageProvider: NFCMessageProvider())
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                debugIDInteractionManager: DebugIDInteractionManager()
            )
        }
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp(),
                                                        nfcMessageProvider: NFCMessageProvider())
        
        environment = AppEnvironment(
            mainQueue: mainQueue,
            uuidFactory: UUID.init,
            idInteractionManager: idInteractionManager
        )
#endif
        
        let homeState = HomeState(appVersion: Bundle.main.version,
                                  buildNumber: Bundle.main.buildNumber)
        
        store = Store(
            initialState: CoordinatorState(states: [.root(.home(homeState), embedInNavigationView: true)]),
            reducer: coordinatorReducer,
            environment: environment
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
