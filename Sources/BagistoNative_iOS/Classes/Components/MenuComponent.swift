import HotwireNative
import UIKit

/// A bridge component that handles displaying a context menu (popup menu) in the navigation bar.
/// This component responds to the "menu" name from the web side.
final class MenuComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "menu" }

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
            addMenuButton(via: message)
        }
    }

    // MARK: - Private Methods

    /// Configures a `UIBarButtonItem` with a `UIMenu` and adds it to the navigation bar.
    /// - Parameter message: The message containing menu items (titles, images).
    private func addMenuButton(via message: Message) {
        guard let data: MessageData = message.data() else { return }

        var actions = [UIAction]()
        for (index, item) in data.items.enumerated() {
            let image = UIImage(systemName: item.image ?? "")
            let action = UIAction(title: item.title, image: image) { [unowned self] _ in
                // Inform the web side which menu item was selected
                reply(to: message.event, with: SelectionMessageData(index: index))
            }
            actions.append(action)
        }

        let button = UIBarButtonItem(
            title: "Menu",
            image: UIImage(systemName: "ellipsis"),
            menu: UIMenu(children: actions)
        )

        viewController?.navigationItem.rightBarButtonItem = button
    }
}

// MARK: - Events

private extension MenuComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Connects the menu and adds the menu button to the navigation bar.
        case connect
    }
}

// MARK: - Data Models

private extension MenuComponent {
    /// The data structure expected in the message from the web side.
    struct MessageData: Decodable {
        /// The list of items to display in the menu.
        let items: [Item]
    }

    /// Represents a single item in the menu.
    struct Item: Decodable {
        /// The display title of the menu item.
        let title: String
        /// The system image name for the menu item.
        let image: String?

        enum CodingKeys: String, CodingKey {
            case title
            case image = "iosImage"
        }
    }

    /// The data structure sent back to the web side when an item is selected.
    struct SelectionMessageData: Encodable {
        /// The index of the selected item in the original list.
        let index: Int
    }
}
