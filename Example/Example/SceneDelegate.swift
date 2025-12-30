import HotwireNative
import WebKit
import UIKit

var rootURL = URL(string: "http://192.168.15.171:3000/")!


var navigator: Navigator? = Navigator(configuration:
    .init(name: "main", startLocation: rootURL)
)
    
class SceneDelegate: UIResponder, UIWindowSceneDelegate, WKNavigationDelegate {
    var window: UIWindow?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("test")
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigator?.rootViewController
        window?.makeKeyAndVisible()
       
        navigator?.start()
         
    }
}


