import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard
import Sentry

@main
struct BundIDApp: App {
    
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        SentrySDK.start { options in
#if PREVIEW
            options.dsn = "https://70d55c1a01854e01a6360cc815b88d34@o1248831.ingest.sentry.io/6589396"
#else
            options.dsn = "https://81bc611af42347bc8d7b487f807f9577@o1248831.ingest.sentry.io/6589505"
#endif
            options.debug = true
            
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
        }
        
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
