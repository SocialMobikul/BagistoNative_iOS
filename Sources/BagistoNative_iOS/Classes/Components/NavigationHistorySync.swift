import HotwireNative
import UIKit
import WebKit

// MARK: - NavigationHistoryComponent

/// A bridge component that synchronizes the web view's navigation history with the native navigation bar.
/// It primarily handles showing or hiding the native back button based on the web view's state.
/// This component responds to the "historysync" name from the web side.
final class NavigationHistoryComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "historysync" }

    // MARK: - Properties

    /// The view controller that's currently displaying the bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    /// Finds the `WKWebView` within the view controller's hierarchy.
    private var wkWebView: WKWebView? {
        viewController?.view.findWKWebView()
    }

    // MARK: - Message Handling

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .history:
            handleHistory(via: message)
        }
    }

    /// Processes the history synchronization message.
    /// - Parameter message: The message containing history metadata.
    private func handleHistory(via message: Message) {
        let jsonString = message.jsonData

        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let metadata = json["metadata"] as? [String: Any] {

                let url = metadata["url"] as? String ?? ""

                // Update back button visibility based on URL presence and web view state
                if !url.isEmpty {
                    showBackButtonIfNeeded()
                } else {
                    hideBackButton()
                }
            }
        } catch {
            print("JSON parsing error: \(error)")
        }
    }

    // MARK: - Back Button Management

    /// Shows a native back button that triggers `webView.goBack()` when tapped.
    private func showBackButtonIfNeeded() {
        guard let webView = wkWebView, webView.canGoBack else {
            hideBackButton()
            return
        }

        let action = UIAction { [weak webView] _ in
            if((webView?.canGoBack ?? false)) {
                webView?.goBack()
            } else {
                self.hideBackButton()
            }
        }

        let item = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            primaryAction: action
        )

        viewController?.navigationItem.leftBarButtonItem = item
    }

    /// Removes the left bar button item (the back button).
    private func hideBackButton() {
        viewController?.navigationItem.leftBarButtonItem = nil
    }
}

// MARK: - Events

private extension NavigationHistoryComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Standard event for history synchronization.
        case history
    }
}

// MARK: - UIView WKWebView Finder (Recursive)

extension UIView {
    /// Recursively searches for a `WKWebView` within the view's subview hierarchy.
    /// - Returns: The found `WKWebView`, or `nil` if not found.
    func findWKWebView() -> WKWebView? {
        if let webView = self as? WKWebView {
            return webView
        }

        for subview in subviews {
            if let found = subview.findWKWebView() {
                return found
            }
        }
        return nil
    }
}
