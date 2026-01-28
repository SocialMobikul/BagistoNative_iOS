import HotwireNative
import StoreKit
import struct HotwireNative.Message

/// A bridge component that handles requesting App Store reviews from the user.
/// This component responds to the "review-prompt" name from the web side.
final class ReviewPromptComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "review-prompt" }

    // MARK: - Properties

    /// The view controller that's currently displaying the bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .prompt:
            promptForReview()
        }
    }

    // MARK: - Private Methods

    /// Triggers the system review prompt.
    private func promptForReview() {
        // Find the window scene to present the review request in
        if let scene = viewController?.view.window?.windowScene {
            if #available(iOS 16.0, *) {
                // Optimal way for iOS 16+
                AppStore.requestReview(in: scene)
            } else {
                // Fallback on earlier versions (no longer supported in latest StoreKit, but logic preserved)
            }
        }
    }
}

// MARK: - Events

private extension ReviewPromptComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Displays the App Store review prompt.
        case prompt
    }
}
