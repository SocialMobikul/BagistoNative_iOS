
import HotwireNative
import UIKit
import WebKit

// MARK: - NavigationHistoryComponent

final class NavigationHistoryComponent: BridgeComponent {

    override class var name: String { "historysync" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - Message Handling

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .history:
            handleHistory(via: message)
        }
    }

    private func handleHistory(via message: Message) {
        let jsonString = message.jsonData

        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let metadata = json["metadata"] as? [String: Any] {

                let url = metadata["url"] as? String ?? ""

                if !url.isEmpty, url != ""{
                    showBackButtonIfNeeded()
                } else {
                    hideBackButton()
                }
            }
        } catch {
            print("JSON parsing error: \(error)")
        }
    }

    // MARK: - Back Button Handling

    private func showBackButtonIfNeeded() {
        guard let webView = wkWebView, webView.canGoBack else {
            hideBackButton()
            return
        }

        let action = UIAction { [weak webView] _ in
            webView?.goBack()
        }

        let item = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            primaryAction: action
        )

        viewController?.navigationItem.leftBarButtonItem = item
    }

    private func hideBackButton() {
        viewController?.navigationItem.leftBarButtonItem = nil
    }

    // MARK: - WKWebView Finder

    private var wkWebView: WKWebView? {
        viewController?.view.findWKWebView()
    }
}

// MARK: - Events

private extension NavigationHistoryComponent {
    enum Event: String {
        case history
    }
}

// MARK: - UIView WKWebView Finder (Recursive)

private extension UIView {
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
