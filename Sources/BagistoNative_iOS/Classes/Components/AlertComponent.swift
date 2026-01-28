import HotwireNative
import UIKit

/// A bridge component that handles presenting native alerts.
/// This component responds to the "alert" name from the web side.
final class AlertComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "alert" }

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
        case .show:
            presentAlert(via: message)
        }
    }

    // MARK: - Private Methods

    /// Presents a native `UIAlertController` based on the data provided in the message.
    /// - Parameter message: The message containing alert configuration (title, description, etc.).
    private func presentAlert(via message: Message) {
        guard let data: MessageData = message.data() else { return }

        let alert = UIAlertController(
            title: data.title,
            message: data.description,
            preferredStyle: .alert
        )

        // Add the primary action (Confirm)
        alert.addAction(UIAlertAction(
            title: data.confirm,
            style: data.confirmActionStyle
        ) { [unowned self] _ in
            // Inform the web side that the user confirmed the alert
            reply(to: message.event)
        })

        // Add the cancellation action (Dismiss)
        alert.addAction(UIAlertAction(
            title: data.dismiss,
            style: .cancel
        ) { _ in })

        viewController?.present(alert, animated: true)
    }
}

// MARK: - Events

private extension AlertComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Displays the alert to the user.
        case show
    }
}

// MARK: - Message Data

private extension AlertComponent {
    /// The data structure expected in the message from the web side.
    struct MessageData: Decodable {
        /// The title of the alert.
        let title: String
        /// The body message of the alert.
        let description: String?
        /// Whether the confirm action should be styled as destructive (red).
        let destructive: Bool
        /// The text for the confirm button.
        let confirm: String
        /// The text for the dismiss button.
        let dismiss: String

        /// Returns the appropriate `UIAlertAction.Style` based on the `destructive` flag.
        var confirmActionStyle: UIAlertAction.Style { destructive ? .destructive : .default }
    }
}
