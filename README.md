# BagistoNative_iOS

**BagistoNative_iOS** provides production-ready **Hotwire Native iOS
bridge components** that enable seamless communication between **Swift
code and web views** in hybrid iOS applications.

Bridge components allow your app to break out of the web view container
and drive **native iOS features** such as scanners, permissions,
haptics, and more --- while still keeping the majority of your UI on the
web.

This library contains reusable, real-world bridge components that can be
easily plugged into any Hotwire Native iOS app.

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
-   Biometrics Lock
-   Button
-   Document Scanner
-   Form
-   Haptic Feedback
-   Location
-   Menu
-   Permissions
-   Review Prompt
-   Search
-   Share
-   Theme
-   Toast

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
