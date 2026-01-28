import HotwireNative
import UIKit

/// A bridge component that handles adding custom buttons to the navigation bar.
/// This component responds to the "button" name from the web side.
final class ButtonComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "button" }

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
        case .connect:
            addButton(via: message)
        }
    }

    // MARK: - Private Methods

    /// Adds a `UIBarButtonItem` to the right side of the navigation bar.
    /// - Parameter message: The message containing button configuration (title, image, etc.).
    private func addButton(via message: Message) {
        guard let data: MessageData = message.data() else { return }

        let image = UIImage(systemName: data.image ?? "")
        let action = UIAction { [unowned self] _ in
            // Inform the web side that the button was tapped
            self.reply(to: message.event)
        }
        let item = UIBarButtonItem(title: data.title, image: image, primaryAction: action)
        viewController?.navigationItem.rightBarButtonItem = item
    }
}

// MARK: - Events

private extension ButtonComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Connects the button to the navigation bar.
        case connect
    }
}

// MARK: - Message Data

private extension ButtonComponent {
    /// The data structure expected in the message from the web side.
    struct MessageData: Decodable {
        /// The title of the button.
        let title: String
        /// The system image name for the button.
        let image: String?

        enum CodingKeys: String, CodingKey {
            case title
            case image = "iosImage"
        }
    }
}
