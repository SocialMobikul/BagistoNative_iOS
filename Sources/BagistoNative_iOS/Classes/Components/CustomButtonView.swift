import HotwireNative
import WebKit
import UIKit

// MARK: - CustomButtonView

/// A versatile bridge component that dynamically manages navigation bar buttons,
/// including cart badges, search/scan actions, and theme switching.
final class CustomButtonView: BridgeComponent {

    /// The name of the bridge component used to register with the web view.
    override class var name: String { "dynamicbutton" }

    // MARK: - Properties

    /// Stores the last received cart-related message to facilitate replies upon button taps.
    private var lastCartMessage: Message?
    /// Observer for cart-related notifications (if applicable).
    private var cartObserver: NSObjectProtocol?

    /// Container view for the custom cart button and its badge.
    private let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30))
    /// The actual button for the cart action.
    private let buttonCart = UIButton(type: .custom)
    /// Label displaying the number of items in the cart.
    private let badgeLabel = UILabel()
    /// Local cache of the cart count.
    private var cartcountValue = 0
    /// Flags to ensure one-time UI and observer configuration.
    private var isUIConfigured = false
    private var isObserverConfigured = false

    /// Accessor for the current window scene's window.
    private var window: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first
    }

    /// The view controller associated with this bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - Hotwire Entry Point

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {

        // 🔑 One-time setup (Hotwire safe)
        configureCartUIIfNeeded()

        guard let event = Event(
            rawValue: message.event
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        ) else {
            print("Invalid event: \(message.event)")
            return
        }

        switch event {
        case .connect, .home:
            viewController?.navigationItem.hidesBackButton = true
            addHomeButton(via: message)
            addHomeButton(via: message)
        case .product:
            addProductButton(via: message)
        case .account:
            addAccountButton(via: message)
        case .navigationbackhide:
            viewController?.navigationItem.hidesBackButton = true
            
        case .modalopen:
            viewController?.navigationItem.hidesBackButton = true
            showCrossButtonIfNeeded(via: message)
            
        case .modaldismiss:
            viewController?.navigationItem.hidesBackButton = true
            showBackButtonIfNeeded()
            
        case .empty:
            self.viewController?.navigationItem.rightBarButtonItems = nil
            self.viewController?.navigationItem.searchController = nil
            
        case .cartcount:
            let jsonString = message.jsonData
            if let data = jsonString.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let count = json["count"] as? String {
                        cartcountValue = Int(count ?? "0") ?? 0
                        DispatchQueue.main.async {
                            self.updateBadge(count: Int(count ?? "0") ?? 0)
                        }
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
            }

        default:
            break
        }
    }

    deinit {
        if let observer = cartObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// Finds the `WKWebView` within the view controller's hierarchy.
    private var wkWebView: WKWebView? {
        viewController?.view.findWKWebView()
    }
    
    /// Configures and shows a "back" button in the navigation bar if the web view can go back.
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
    
    /// Replaces the back button with a "cross" (dismiss) button, typically for modals.
    /// - Parameter message: The message that triggered the cross button.
    private func showCrossButtonIfNeeded(via message: Message) {
        if let webView = wkWebView {
            hideBackButton()
            let action = UIAction { [weak webView] _ in
                if((webView?.canGoBack ?? false)) {
                    self.showBackButtonIfNeeded()
                } else {
                    self.hideBackButton()
                }
                // Notify the web side that the modal was dismissed
                self.reply(to: message.event, with: ["type": "modal_dismiss"])
            }

            let item = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                primaryAction: action
            )

            viewController?.navigationItem.leftBarButtonItem = item
        }
       
    }

    /// Removes the left bar button item (the back button).
    private func hideBackButton() {
        viewController?.navigationItem.leftBarButtonItem = nil
    }
}

// MARK: - WKWebView Finder




// MARK: - UI Setup (Lazy initialization)

private extension CustomButtonView {

    /// Sets up the cart button and badge label once.
    func configureCartUIIfNeeded() {
        guard !isUIConfigured else { return }
        isUIConfigured = true

        // Cart Button styling
        let image = UIImage(systemName: "cart")?.withRenderingMode(.alwaysTemplate)
        buttonCart.setImage(image, for: .normal)
        buttonCart.tintColor = .systemBlue
        buttonCart.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        buttonCart.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        // Badge Label styling
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = .systemRed
        badgeLabel.font = .systemFont(ofSize: 12, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        badgeLabel.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        badgeLabel.addGestureRecognizer(tapGesture)

        // Add subviews ONLY ONCE
        container.addSubview(buttonCart)
        container.addSubview(badgeLabel)
    }
}

// MARK: - Badge Handling

private extension CustomButtonView {

    /// Updates the badge appearance and visibility based on the count.
    /// - Parameter count: The number of items to display in the badge.
    func updateBadge(count: Int) {
        guard count > 0 else {
            badgeLabel.isHidden = true
            return
        }

        badgeLabel.isHidden = false
        badgeLabel.text = count > 99 ? "99+" : "\(count)"

        let padding: CGFloat = 8
        let minWidth: CGFloat = 20
        let height: CGFloat = 20

        let textWidth = badgeLabel.intrinsicContentSize.width + padding
        let badgeWidth = max(minWidth, textWidth)

        badgeLabel.frame = CGRect(
            x: buttonCart.frame.maxX - badgeWidth / 2,
            y: -6,
            width: badgeWidth,
            height: height
        )

        badgeLabel.layer.cornerRadius = height / 2
    }
}


// MARK: - Navigation Bar Buttons

private extension CustomButtonView {

    /// Creates a `UIBarButtonItem` containing the custom cart button and badge.
    /// - Returns: A bar button item with the container as its custom view.
    func cartBarButtonItem() -> UIBarButtonItem {
        
        updateBadge(count: cartcountValue)
        return UIBarButtonItem(customView: container)
    }

    /// Adds the "Home" context buttons to the navigation bar: Cart, QR Scan, and Barcode Scan.
    /// - Parameter message: The message containing home configuration.
    func addHomeButton(via message: Message) {
        guard let _: MessageData = message.data() else { return }
        lastCartMessage = message
        
        let jsonString = message.jsonData
        if let data = jsonString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let count = json["cart"] as? String {
                    cartcountValue = Int(count ?? "0") ?? 0
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }

        let cartItem = cartBarButtonItem()

        let scanAction = UIAction { [weak self] _ in
            self?.presentScanner(for: message)
        }

        let scanItem = UIBarButtonItem(
            title: "",
            image: UIImage(systemName: "barcode.viewfinder"),
            primaryAction: scanAction
        )

        let mlAction = UIAction { [weak self] _ in
            self?.presentMlScanner(for: message)
        }

        let mlItem = UIBarButtonItem(
            title: "",
            image: UIImage(systemName: "camera.viewfinder"),
            primaryAction: mlAction
        )
        
        viewController?.navigationItem.rightBarButtonItems = [
            cartItem,
            scanItem,
            mlItem
        ]
    }

    /// Adds the "Product" context buttons to the navigation bar: Cart and Share.
    /// - Parameter message: The message containing product configuration.
    func addProductButton(via message: Message) {
        guard let _: MessageData = message.data() else { return }
        lastCartMessage = message

        let jsonString = message.jsonData
        if let data = jsonString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let count = json["cart"] as? String {
                    cartcountValue = Int(count ?? "0") ?? 0
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }
        
        let cartItem = cartBarButtonItem()

        let shareAction = UIAction { [weak self] _ in
            guard
                let urlString = message.metadata?.url,
                let url = URL(string: urlString)
            else { return }
            self?.share(url)
        }

        let shareItem = UIBarButtonItem(
            title: "",
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: shareAction
        )

        viewController?.navigationItem.rightBarButtonItems = [
            cartItem,
            shareItem
        ]
    }

    /// Adds the "Account" context buttons to the navigation bar: Theme Toggle.
    /// - Parameter message: The message containing account configuration.
    func addAccountButton(via message: Message) {
        guard let _: MessageData = message.data() else { return }

        let themeAction = UIAction { [weak self] _ in
            guard let self = self else { return }

            let style = self.window?.overrideUserInterfaceStyle
            let isDark = style == .dark ||
                (style == .unspecified && UITraitCollection.current.userInterfaceStyle == .dark)

            self.window?.overrideUserInterfaceStyle = isDark ? .light : .dark
            self.reply(
                to: message.event,
                with: ["type": "theme", "code": isDark ? "light" : "dark"]
            )
        }

        let themeItem = UIBarButtonItem(
            title: "",
            image: UIImage(systemName: "sun.max.fill"),
            primaryAction: themeAction
        )

        viewController?.navigationItem.rightBarButtonItems = [themeItem]
    }
}

// MARK: - Actions

private extension CustomButtonView {

    /// Action called when the cart button is tapped. Replies to the web side with "cart" type.
    @objc func buttonTapped() {
        guard let message = lastCartMessage else { return }
        reply(to: message.event, with: ["type": "cart"])
    }

    /// Action called when the badge label is tapped. Replies to the web side with "cart" type.
    @objc func labelTapped() {
        guard let message = lastCartMessage else { return }
        reply(to: message.event, with: ["type": "cart"])
    }
}

// MARK: - Scanner & Sharing

private extension CustomButtonView {

    /// Presents the system share sheet for the given URL.
    /// - Parameter url: The URL to share.
    func share(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let popover = vc.popoverPresentationController {
            popover.sourceView = viewController?.view
            popover.sourceRect = CGRect(
                x: viewController?.view.bounds.midX ?? 0,
                y: viewController?.view.bounds.midY ?? 0,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController?.present(vc, animated: true)
    }

    /// Presents the custom barcode scanner.
    /// - Parameter message: The message that triggered the scan action.
    func presentScanner(for message: Message) {
        guard let presenter = viewController else { return }

        let scannerVC = BarcodeScannerViewController()
        scannerVC.onScanComplete = { [weak self] result in
            scannerVC.dismiss(animated: true) {
                self?.reply(to: message.event, with: ["type": "scan", "code": result])
            }
        }

        presenter.present(scannerVC, animated: true)
    }

    /// Presents an action sheet to choose between Object Detection and Text Recognition.
    /// - Parameter message: The message that triggered the ML scan action.
    func presentMlScanner(for message: Message) {
        guard let presenter = viewController else { return }
        self.presentMLSearch(with: .image, message, presenter)
    }

    /// Presents the ML Image Search view controller.
    /// - Parameters:
    ///   - type: The type of search (image/object or text).
    ///   - message: The message that triggered the ML search.
    ///   - controller: The view controller to present from.
    func presentMLSearch(
        with type: MLSearchType,
        _ message: Message,
        _ controller: UIViewController
    ) {
        let vc = MLImageSearchViewController()
        vc.searchType = type
        vc.callBack = { [weak self] result in
            self?.reply(
                to: message.event,
                with: ["type": "scan", "code": result]
            )
        }

        vc.modalPresentationStyle = .popover

        if let popover = vc.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(
                x: controller.view.bounds.midX,
                y: controller.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        controller.present(vc, animated: true)

    }
}

// MARK: - Supporting Types

private extension CustomButtonView {

    enum Event: String {
        case connect
        case home
        case product
        case account
        case navigationbackhide
        case cartcount
        case modalopen
        case modaldismiss
        case empty
    }

    struct MessageData: Decodable {
        let title: String?
        let image: String?

        enum CodingKeys: String, CodingKey {
            case title
            case image = "iosImage"
        }
    }
}

