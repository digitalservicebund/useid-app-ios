import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard
import Sentry

func parseArguments() -> [String: String] {
    var arguments = [String: String]()
    for argument in ProcessInfo.processInfo.arguments[1...] {
        let keyValues = argument.split(separator: "=", maxSplits: 1)
        guard keyValues.count >= 1 && keyValues.count <= 2 else { continue }
        let key = keyValues.first!
        let value = keyValues.count > 1 ? keyValues.last! : "1"
        arguments[String(key)] = String(value)
    }
    return arguments
}

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
            let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                debugIDInteractionManager: DebugIDInteractionManager()
            )
        }
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
        
        environment = AppEnvironment(
            mainQueue: mainQueue,
            uuidFactory: UUID.init,
            idInteractionManager: idInteractionManager
        )
#endif
        
        let arguments = parseArguments()
#if PREVIEW
        let tokenURL: String? = arguments["TOKEN_URL"]
#else
        let tokenURL: String? = nil
#endif
        
        let homeState = HomeState(appVersion: Bundle.main.version,
                                  buildNumber: Bundle.main.buildNumber)
        
        store = Store(
            initialState: CoordinatorState(tokenURL: tokenURL, states: [.root(.home(homeState), embedInNavigationView: false)]),
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
