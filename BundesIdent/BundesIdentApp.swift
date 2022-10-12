import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard
import Sentry
import Analytics

@main
struct BundesIdentApp: App {
    
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
            options.enabled = false
#endif
#if SENTRY_DEBUG
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
        let matomoUrl = URL(string: "https://bund.matomo.cloud/matomo.php")!
        
#if PREVIEW
        if MOCK_OPENECARD {
            let idInteractionManager = DebugIDInteractionManager()
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                storageManager: storageManager,
                analytics: MatomoAnalyticsClient(siteId: "2", baseURL: matomoUrl),
                urlOpener: { UIApplication.shared.open($0) },
                issueTracker: SentryIssueTracker(),
                debugIDInteractionManager: idInteractionManager
            )
        } else {
            let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                storageManager: storageManager,
                analytics: MatomoAnalyticsClient(siteId: "2", baseURL: matomoUrl),
                urlOpener: { UIApplication.shared.open($0) },
                issueTracker: SentryIssueTracker(),
                debugIDInteractionManager: DebugIDInteractionManager()
            )
        }
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
        
        environment = AppEnvironment(
            mainQueue: mainQueue,
            uuidFactory: UUID.init,
            idInteractionManager: idInteractionManager,
            storageManager: storageManager,
            analytics: MatomoAnalyticsClient(siteId: "3", baseURL: matomoUrl),
            urlOpener: { UIApplication.shared.open($0) },
            issueTracker: SentryIssueTracker()
        )
#endif
        
        store = Store(
            initialState: CoordinatorState(
                routes: [
                    .root(.home(HomeState(appVersion: Bundle.main.version, buildNumber: Bundle.main.buildNumber)))
                ]
            ),
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
                    let viewStore = ViewStore(store.stateless)
                    viewStore.send(.onAppear)
                    
#if PREVIEW
                    if CommandLine.arguments.contains(LaunchArgument.useDemoTokenURL) {
                        viewStore.send(.openURL(demoTokenURL))
                    }
                    
                    if CommandLine.arguments.contains(LaunchArgument.uiTesting) {
                        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        windowScene?.windows.first?.layer.speed = 100
                        UIView.setAnimationsEnabled(false)
                    }
#endif
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    ViewStore(store.stateless).send(.didEnterBackground)
                }
                .accentColor(Color(asset: Asset.accentColor))
        }
        
    }
}
