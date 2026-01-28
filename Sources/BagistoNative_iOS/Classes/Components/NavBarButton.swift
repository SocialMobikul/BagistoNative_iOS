import HotwireNative
import UIKit

/// A bridge component that dynamically adds or removes buttons from the navigation bar.
/// This component responds to the "nav-buttono" name from the web side.
final class NavButtonComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "nav-buttono" }

    // MARK: - Properties

    /// Local cache of added buttons to facilitate easy removal.
    private var buttons: [String: UIBarButtonItem] = [:]

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
        case .add:
            handleAddEvent(via: message)

        case .remove:
            handleRemoveEvent(via: message)
        }
    }

    // MARK: - Private Methods

    /// Handles the "add" event by creating and adding a button to the navigation bar.
    /// - Parameter message: The message containing button configuration.
    private func handleAddEvent(via message: Message) {
        let jsonString = message.jsonData 
        if let data = jsonString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let url = json["url"] as? String
                    let action = UIAction { [weak self] _ in
                        guard let url = URL(string: url ?? "") else { return }
                        self?.visit(url)
                    }
                    let item = UIBarButtonItem(
                        title: "",
                        image: UIImage(systemName: "cart"),
                        primaryAction: action
                    )
                    
                    // Cache the button for later removal
                    buttons["cart"] = item
                    
                    // Add the button to the navigation items
                    var items = viewController?.navigationItem.rightBarButtonItems ?? []
                    items.append(item)
                    viewController?.navigationItem.rightBarButtonItems = items
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }
    }

    /// Handles the "remove" event by removing a previously added button.
    /// - Parameter message: The message identifying the button to remove.
    private func handleRemoveEvent(via message: Message) {
        if let data: ButtonData = message.data(), let item = buttons[data.type] {
            viewController?.navigationItem.rightBarButtonItems?.removeAll(where: { $0 == item })
            buttons.removeValue(forKey: data.type)
        }
    }

    /// Performs a Hotwire visit to the specified URL.
    /// - Parameter url: The URL to visit.
    private func visit(_ url: URL) {
        if let delegate = delegate as? VisitableDelegate {
            delegate.visit(url: url, options: VisitOptions(action: .advance))
        }
    }
}

// MARK: - Events

extension NavButtonComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Adds a button to the navigation bar.
        case add
        /// Removes a button from the navigation bar.
        case remove
    }
}

// MARK: - Message Data

extension NavButtonComponent {
    /// The data structure expected in the message from the web side.
    struct ButtonData: Decodable {
        let type: String
        let title: String
        let url: String
        let iosImage: String
        let androidImage: String
    }
}

// MARK: - VisitableDelegate

/// Protocol definition for a delegate that can handle Hotwire visits.
protocol VisitableDelegate: BridgingDelegate {
    func visit(url: URL, options: VisitOptions)
}
