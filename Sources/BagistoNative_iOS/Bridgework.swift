
import HotwireNative
import UIKit

public enum Bridgework {}

public extension Bridgework {

    // MARK: - Hotwire Components
    static let coreComponents = [
        AlertComponent.self,
        NavButtonComponent.self,
        ImageSearchComponent.self,
        BarcodeScannerComponent.self,
        LocationComponent.self,
        FormComponent.self,
        HapticComponent.self,
        MenuComponent.self,
        ReviewPromptComponent.self,
        SearchComponent.self,
        ThemeComponent.self,
        ToastComponent.self,
        CustomButtonView.self,
        FileViewerComponent.self,
        NavigationHistoryComponent.self
    ]

    // MARK: - Navigation Bar Appearance
    static func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()

        // ✅ Proper translucent (blur) – NOT fully transparent
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        appearance.shadowColor = .clear

        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]

        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.isTranslucent = true
    }
}
