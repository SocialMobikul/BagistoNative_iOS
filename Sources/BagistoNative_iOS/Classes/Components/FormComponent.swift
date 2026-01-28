import HotwireNative
import UIKit

/// A bridge component that handles form submission coordination, 
/// such as adding a "Submit" button to the navigation bar.
/// This component responds to the "form" name from the web side.
final class FormComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "form" }

    // MARK: - Properties

    /// Reference to the submit button in the navigation bar.
    private weak var submitBarButtonItem: UIBarButtonItem?

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
        case .connect:
            addButton(via: message)
        case .enableSubmit:
            enableButton()
        case .disableSubmit:
            disableButton()
        }
    }

    // MARK: - Private Methods

    /// Adds a submit button to the navigation bar's right side.
    /// - Parameter message: The message containing button configuration.
    private func addButton(via message: Message) {
        guard let data: MessageData = message.data() else { return }

        let action = UIAction { [unowned self] _ in
            // Inform the web side that the submit button was tapped
            reply(to: message.event)
        }

        let item = UIBarButtonItem(title: data.title, primaryAction: action)
        viewController?.navigationItem.rightBarButtonItem = item
        submitBarButtonItem = item
    }

    /// Enables the submit button.
    private func enableButton() {
        submitBarButtonItem?.isEnabled = true
    }

    /// Disables the submit button.
    private func disableButton() {
        submitBarButtonItem?.isEnabled = false
    }
}

// MARK: - Events

private extension FormComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Connects the form and adds the submit button.
        case connect
        /// Enables the submit button (e.g., when the form is valid).
        case enableSubmit
        /// Disables the submit button (e.g., when the form is invalid).
        case disableSubmit
    }
}

// MARK: - Message Data

private extension FormComponent {
    /// The data structure expected in the message from the web side.
    struct MessageData: Decodable {
        /// The title for the submit button.
        let title: String
    }
}
