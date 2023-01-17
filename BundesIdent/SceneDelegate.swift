import Foundation
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        (scene as? UIWindowScene)?.keyWindow?.tintColor = Asset.accentColor.color
    }
    
}
