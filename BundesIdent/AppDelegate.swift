import Foundation
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setNavigationBarFont()
        addAccessibilityObservers()
        return true
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
        
        let button = UIBarButtonItemAppearance(style: .plain)
        button.normal.titleTextAttributes = [.font: UIFont.bundNavigationBar]
        standard.buttonAppearance = button
        standard.backButtonAppearance = button
        
        let done = UIBarButtonItemAppearance(style: .done)
        done.normal.titleTextAttributes = [.font: UIFont.bundNavigationBar]
        standard.doneButtonAppearance = done
        
        UINavigationBar.appearance().standardAppearance = standard
    }
}
