import HotwireNative
import UIKit

/// A bridge component that handles theme switching (light/dark mode) requests.
/// This component responds to the "thememode" name from the web side.
class ThemeComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override static var name: String { "thememode" }

    // MARK: - Properties

    /// Accessor for the current window scene's window to override user interface style.
    private var window: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first
    }

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the theme mode.
    override func onReceive(message: Message) {
        // Attempt to decode the message data into our Theme enum
        guard let data: MessageData = message.data() else { return }
        
        // Update the window's user interface style based on the provided theme
        switch data.mode {
        case .dark:
            self.window?.overrideUserInterfaceStyle = .dark
        case .light:
            self.window?.overrideUserInterfaceStyle = .light
        case nil:
            break
        }
    }
}

// MARK: - Data Models

private extension ThemeComponent {
    /// The data structure expected in the message from the web side.
    struct MessageData: Decodable {
        /// The theme mode requested by the web side.
        let mode: Theme?
    }

    /// Supported theme modes.
    enum Theme: String, Decodable {
        case light
        case dark
    }
}
