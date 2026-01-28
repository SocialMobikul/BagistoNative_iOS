import HotwireNative
import UIKit

/// A bridge component that handles sharing URLs and managing cart buttons in the navigation bar.
/// This component responds to the "share" name from the web side.
final class MobikulShareButtonComponent: BridgeComponent {

    /// The name of the bridge component used to register with the web view.
    override class var name: String { "share" }

    // MARK: - Properties

    /// The view controller that's currently displaying the bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// Handles both "share" and "cart" types of interactions.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        let jsonString = message.jsonData
        if let data = jsonString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let type = json["type"] as? String
                    switch type {
                    case "share":
                        handleConnect(message: message)
                    case "cart":
                        handleClick(message: message)
                    default:
                        print("Unhandled type: \(type ?? "nil")")
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }

        // Validate event if needed for future use
        guard let _ = Event(rawValue: message.event) else { return }
    }

    // MARK: - Message Handlers

    /// Configures buttons in the navigation bar based on the "connect" logic.
    /// - Parameter message: The message containing connection details.
    private func handleConnect(message: Message) {
        guard let data: MessageData = message.data() else { return }

        switch data.type {
        case "share":
            addShareButton(url: data.url)
        case "cart":
            addCartButton(url: data.url)
        default:
            print("Unknown connect type: \(data.type ?? "nil")")
        }
    }

    /// Handles click interactions, specifically for the cart button.
    /// - Parameter message: The message containing click details.
    private func handleClick(message: Message) {
        guard let data: MessageData = message.data() else { return }

        switch data.type {
        case "cart":
            let action = UIAction { [unowned self] _ in
                // Inform the web side that the cart button was tapped
                self.reply(to: message.event)
            }

            let cartButton = UIBarButtonItem(
                title: "",
                image: UIImage(systemName: "cart"),
                primaryAction: action
            )
            addNavItem(cartButton)
        default:
            print("Unknown click type: \(data.type ?? "nil")")
        }
    }

    // MARK: - Navigation Bar Management

    /// Adds a share button to the navigation bar.
    /// - Parameter url: The URL to be shared.
    private func addShareButton(url: URL?) {
        guard let url else { return }

        let action = UIAction { [unowned self] _ in
            self.share(url)
        }

        let shareButton = UIBarButtonItem(
            title: "Share",
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: action
        )

        addNavItem(shareButton)
    }

    /// Adds a cart button to the navigation bar.
    /// - Parameter url: The URL to navigate to when the cart button is tapped (optional).
    private func addCartButton(url: URL?) {
        let action = UIAction { [unowned self] _ in
            self.openCart(url)
        }

        let cartButton = UIBarButtonItem(
            title: "Cart",
            image: UIImage(systemName: "cart"),
            primaryAction: action
        )

        addNavItem(cartButton)
    }

    /// Appends a new bar button item to the right side of the navigation bar.
    /// - Parameter item: The item to add.
    private func addNavItem(_ item: UIBarButtonItem) {
        var items = viewController?.navigationItem.rightBarButtonItems ?? []
        items.append(item)
        viewController?.navigationItem.rightBarButtonItems = items
    }

    // MARK: - Actions

    /// Displays the system share sheet.
    /// - Parameter url: The URL to share.
    private func share(_ url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        viewController?.present(activityViewController, animated: true)
    }

    /// Opens the cart URL in the system browser or app.
    /// - Parameter url: The cart URL to open.
    private func openCart(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Events

extension MobikulShareButtonComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Initial connection/setup of buttons.
        case connect
        /// Handling click interactions.
        case click
    }
}

// MARK: - Message Data

/// Data structure for messages received by the Share component.
struct MessageData: Decodable {
    /// The URL associated with the action.
    let urlString: String
    /// The type of item (share, cart, etc.).
    let type: String?

    /// Converts the string URL to a `URL` object.
    var url: URL? {
        URL(string: urlString)
    }

    enum CodingKeys: String, CodingKey {
        case urlString = "url"
        case type
    }
}
