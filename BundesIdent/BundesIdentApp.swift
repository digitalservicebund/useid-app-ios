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
        let config = AppConfig(bundle: Bundle.main)
        SentrySDK.start(configureOptions: config.configureSentry)
        
        let userDefaults = UserDefaults.standard
        if CommandLine.arguments.contains(LaunchArgument.resetUserDefaults) {
            userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
        
        if CommandLine.arguments.contains(LaunchArgument.setupCompleted) {
            userDefaults.set(true, forKey: StorageKey.setupCompleted.rawValue)
        }
        
        let environment = AppEnvironment.live(appConfig: config)
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
        }
    }
}
