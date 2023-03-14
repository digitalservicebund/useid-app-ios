import Foundation
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setNavigationBarFont()
        addAccessibilityObservers()
        return true
    }
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

extension AppDelegate {
    private func addAccessibilityObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setNavigationBarFont),
                                               name: UIAccessibility.boldTextStatusDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setNavigationBarFont),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }
    
    @objc
    private func setNavigationBarFont() {
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.titleTextAttributes = [.font: UIFont.bundNavigationBarBold]
        
        let plainButton = UIBarButtonItemAppearance(style: .plain)
        plainButton.normal.titleTextAttributes = [.font: UIFont.bundNavigationBar]
        standard.buttonAppearance = plainButton
        standard.backButtonAppearance = plainButton
        
        UINavigationBar.appearance().standardAppearance = standard
        
        // Toolbar bar button items
        
        UIBarButtonItem.appearance().setTitleTextAttributes([
            .font: UIFont.bundNavigationBar,
            .foregroundColor: Asset.accentColor.color
        ], for: .normal)
        
        for state in [UIControl.State.disabled, .focused, .highlighted, .selected] {
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: UIFont.bundNavigationBar], for: state)
        }
    }
}
