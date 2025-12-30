# BagistoNative_iOS

**BagistoNative_iOS** provides production-ready **Hotwire Native iOS
bridge components** that enable seamless communication between **Swift
code and web views** in hybrid iOS applications.

Bridge components allow your app to break out of the web view container
and drive **native iOS features** such as scanners, ml search,
download, review and more --- while still keeping the majority of your UI on the
web.

This library contains reusable, real-world bridge components that can be
easily plugged into any Hotwire Native iOS app.

To find out more, visit: https://mobikul.com/

------------------------------------------------------------------------

## ✨ Features

-   Native iOS bridge components for Hotwire Native
-   Plug-and-play architecture
-   Designed for production use
-   Easy to extend and customize
-   Swift Package Manager support

------------------------------------------------------------------------

## 📦 Components

The following bridge components are included:

-   Alert
-   Barcode Scanner
-   Button
-   Form
-   Haptic Feedback
-   Location
-   Review Prompt
-   Search
-   Share
-   Theme
-   Toast
-   Download
-   Image Search
-   Navigation Stack
 

------------------------------------------------------------------------

## 📋 Requirements

-   iOS 14.0+
-   Swift 5.7+
-   Hotwire Native iOS v1.2 or later

------------------------------------------------------------------------

## 🚀 Installation (Swift Package Manager)

### Add the package dependency

In Xcode:

File → Add Package Dependencies...

Repository URL:

https://github.com/SocialMobikul/BagistoNative_iOS

------------------------------------------------------------------------

### Register bridge components

``` swift
import UIKit
import HotwireNative
import BagistoNative_iOS

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        Hotwire.registerBridgeComponents(BagistoNative.coreComponents)
        return true
    }
}
```
### Configuration Example

You can configure your starting URL and navigator in your SceneDelegate:
``` swift
import HotwireNative
import UIKit

// MARK: - App Configuration
struct AppConfig {
    static var baseURL: URL = URL(string: "base_url")!
}

// MARK: - Navigator Setup
var navigator: Navigator? = {
    let config = Navigator.Configuration(name: "main", startLocation: AppConfig.baseURL)
    return Navigator(configuration: config)
}()

// MARK: - Scene Delegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate, WKNavigationDelegate {
    
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
```
------------------------------------------------------------------------

## 🧪 Examples

Check the `Examples/` directory for a demo iOS application showcasing
usage of the bridge components.

------------------------------------------------------------------------

## 🆘 Need Help?

Open an issue or start a discussion in the repository if you need help.

------------------------------------------------------------------------

## 📄 License

MIT License

------------------------------------------------------------------------

## 📌 About

BagistoNative_iOS\
Native iOS bridge components for Hotwire Native applications.
