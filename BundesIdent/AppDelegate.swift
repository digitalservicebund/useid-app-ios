import Foundation
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setNavigationBarFont()
        return true
    }
}

extension AppDelegate {
    private func setNavigationBarFont() {
        let standard = UINavigationBarAppearance()
        standard.configureWithTransparentBackground()
        standard.titleTextAttributes = [.font: UIFont.bundNavigationBar]
        
        let button = UIBarButtonItemAppearance(style: .plain)
        button.normal.titleTextAttributes = [.font: UIFont.bundNavigationBar]
        standard.buttonAppearance = button
        
        let done = UIBarButtonItemAppearance(style: .done)
        done.normal.titleTextAttributes = [.font: UIFont.bundNavigationBar]
        standard.doneButtonAppearance = done

        UINavigationBar.appearance().standardAppearance = standard
    }
}
