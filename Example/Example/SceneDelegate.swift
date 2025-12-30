import HotwireNative
import UIKit

// MARK: - App Configuration
struct AppConfig {
    static var baseURL: URL = URL(string: "http://192.168.15.171:3000/")!
}

// MARK: - Navigator Setup
var navigator: Navigator? = {
    let config = Navigator.Configuration(name: "main", startLocation: AppConfig.baseURL)
    return Navigator(configuration: config)
}()

// MARK: - Scene Delegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigator?.rootViewController
        window?.makeKeyAndVisible()

        navigator?.start()
    }
}
