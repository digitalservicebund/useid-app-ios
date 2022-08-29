import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard
import Sentry

@main
struct BundIDApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var store: Store<CoordinatorState, CoordinatorAction>
    
    init() {
        SentrySDK.start { options in
#if PREVIEW
            options.dsn = "https://70d55c1a01854e01a6360cc815b88d34@o1248831.ingest.sentry.io/6589396"
#else
            options.dsn = "https://81bc611af42347bc8d7b487f807f9577@o1248831.ingest.sentry.io/6589505"
#endif
#if DEBUG
            options.debug = true
#endif
            options.tracesSampleRate = 1.0
        }
        let userDefaults = UserDefaults.standard
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        let environment: AppEnvironment
        
        if CommandLine.arguments.contains(LaunchArgument.resetUserDefaults) {
            userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
        
        if CommandLine.arguments.contains(LaunchArgument.setupCompleted) {
            userDefaults.set(true, forKey: StorageKey.setupCompleted.rawValue)
        }
        
        let storageManager = StorageManager(userDefaults: userDefaults)
        
#if PREVIEW
        if MOCK_OPENECARD {
            let idInteractionManager = DebugIDInteractionManager()
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                storageManager: storageManager,
                debugIDInteractionManager: idInteractionManager
            )
        } else {
            let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                storageManager: storageManager,
                debugIDInteractionManager: DebugIDInteractionManager()
            )
        }
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
        
        environment = AppEnvironment(
            mainQueue: mainQueue,
            uuidFactory: UUID.init,
            idInteractionManager: idInteractionManager,
            storageManager: storageManager
        )
#endif
        
#if PREVIEW
        let tokenURL: String? = CommandLine.arguments.contains(LaunchArgument.useDemoTokenURL) ? demoTokenURL : nil
#else
        let tokenURL: String? = nil
#endif
        
        let homeState = HomeState(appVersion: Bundle.main.version,
                                  buildNumber: Bundle.main.buildNumber)
        
        let coordinatorState = CoordinatorState(
            tokenURL: tokenURL,
            states: [
                .root(.home(homeState), embedInNavigationView: false)
            ]
        )
        
        store = Store(
            initialState: coordinatorState,
            reducer: coordinatorReducer,
            environment: environment
        )
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView(store: store)
                .onOpenURL { url in
                    ViewStore(store.stateless).send(.openURL(url))
                }
                .onAppear {
                    ViewStore(store.stateless).send(.onAppear)
                }
        }
    }
}
