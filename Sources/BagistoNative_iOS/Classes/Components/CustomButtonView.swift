import HotwireNative
import UIKit


// MARK: - CustomButtonView

final class CustomButtonView: BridgeComponent {

    override class var name: String { "dynamicbutton" }

    // MARK: - Properties

    private var lastCartMessage: Message?
    private var cartObserver: NSObjectProtocol?

    private let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30))
    private let buttonCart = UIButton(type: .custom)
    private let badgeLabel = UILabel()
    private var cartcountValue = 0
    private var isUIConfigured = false
    private var isObserverConfigured = false

    private var window: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first
    }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - Hotwire Entry Point

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
            addHomeButton(via: message)

        case .product:
            addProductButton(via: message)

        case .account:
            addAccountButton(via: message)

        case .navigationbackhide:
            viewController?.navigationItem.hidesBackButton = true
            print("")
            
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
}

// MARK: - UI Setup (ONLY ONCE)

private extension CustomButtonView {

    func configureCartUIIfNeeded() {
        guard !isUIConfigured else { return }
        isUIConfigured = true

        // Cart Button
        let image = UIImage(systemName: "cart")?.withRenderingMode(.alwaysTemplate)
        buttonCart.setImage(image, for: .normal)
        buttonCart.tintColor = .systemBlue
        buttonCart.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        buttonCart.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        // Badge Label
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

    func cartBarButtonItem() -> UIBarButtonItem {
        
        updateBadge(count: cartcountValue)
        return UIBarButtonItem(customView: container)
    }

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
            image: UIImage(systemName: "qrcode"),
            primaryAction: scanAction
        )

        let mlAction = UIAction { [weak self] _ in
            self?.presentMlScanner(for: message)
        }

        let mlItem = UIBarButtonItem(
            title: "",
            image: UIImage(systemName: "barcode.viewfinder"),
            primaryAction: mlAction
        )

        viewController?.navigationItem.rightBarButtonItems = [
            cartItem,
            scanItem,
            mlItem
        ]
    }

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

    @objc func buttonTapped() {
        guard let message = lastCartMessage else { return }
        reply(to: message.event, with: ["type": "cart"])
    }

    @objc func labelTapped() {
        guard let message = lastCartMessage else { return }
        reply(to: message.event, with: ["type": "cart"])
    }
}

// MARK: - Scanner & Sharing

private extension CustomButtonView {

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

    func presentMlScanner(for message: Message) {
        guard let presenter = viewController else { return }

        let alert = UIAlertController(title: "Select Option", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Detect Object", style: .default) { _ in
            self.presentMLSearch(with: .image, message, presenter)
        })

        alert.addAction(UIAlertAction(title: "Read Text", style: .default) { _ in
            self.presentMLSearch(with: .text, message, presenter)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        presenter.present(alert, animated: true)
    }

    func presentMLSearch(
        with type: MLSearchType,
        _ message: Message,
        _ controller: UIViewController
    ) {
        let vc = MLImageSearchViewController()   // ✅ No storyboard

           vc.searchType = type
           vc.callBack = { [weak self] result in
               self?.reply(
                   to: message.event,
                   with: ["type": "scan", "code": result]
               )
           }

           vc.modalPresentationStyle = .fullScreen
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

