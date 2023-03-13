import SwiftUI
import TCACoordinators
import ComposableArchitecture
import OpenEcard
import Sentry
import Analytics
import XCTestDynamicOverlay

@main
struct BundesIdentApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var store: Store<Coordinator.State, Coordinator.Action>
    
    init() {
        let config = AppConfig(bundle: Bundle.main)
        SentrySDK.start(configureOptions: config.configureSentry)
        
        config.configureAudio()
        
        let userDefaults = UserDefaults.standard
        if CommandLine.arguments.contains(LaunchArgument.resetUserDefaults) {
            userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
        
        if CommandLine.arguments.contains(LaunchArgument.setupCompleted) {
            userDefaults.set(true, forKey: StorageKey.setupCompleted.rawValue)
        }
        
        if CommandLine.arguments.contains(LaunchArgument.identifiedOnce) {
            userDefaults.set(true, forKey: StorageKey.identifiedOnce.rawValue)
        }
        
#if DEBUG
        AnalyticsKey.liveValue = LogAnalyticsClient()
#else
        AnalyticsKey.liveValue = MatomoAnalyticsClient(siteId: config.matomoSiteID, baseURL: config.matomoURL)
#endif
        
        let homeState: Home.State
#if PREVIEW
        let previewIDInteractionManager = DependencyValues._current[keyPath: \.previewIDInteractionManager]
        homeState = Home.State(appVersion: Bundle.main.version, buildNumber: Bundle.main.buildNumber, isDebugModeEnabled: previewIDInteractionManager.isDebugModeEnabled)
#else
        homeState = Home.State(appVersion: Bundle.main.version, buildNumber: Bundle.main.buildNumber)
#endif
        
        store = Store(
            initialState: Coordinator.State(
                routes: [
                    .root(.home(homeState))
                ]
            ),
            reducer: Coordinator()
        )
    }
    
    var body: some Scene {
        WindowGroup {
            if !XCTestDynamicOverlay._XCTIsTesting {
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
}
