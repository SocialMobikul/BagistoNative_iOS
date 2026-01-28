import HotwireNative
import UIKit

/// A bridge component that displays brief "toast" notification messages to the user.
/// This component responds to the "toast" name from the web side.
final class ToastComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "toast" }

    // MARK: - Properties

    /// The view controller that's currently displaying the bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the toast text.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .show:
            showToast(via: message)
        }
    }

    // MARK: - Private Methods

    /// Creates and animates a toast message label in the view controller's view.
    /// - Parameter message: The message containing the text to display.
    private func showToast(via message: Message) {
        guard let data: MessageData = message.data(), let viewController else { return }

        let toast = makeLabel(text: data.message)
        viewController.view.addSubview(toast)
        constrainToast(toast, in: viewController.view)
        animateToastInAndOut(toast)
    }

    /// Creates a styled `UILabel` with padding for the toast.
    /// - Parameter text: The message text.
    /// - Returns: A configured `PaddingLabel`.
    private func makeLabel(text: String) -> UILabel {
        let label = PaddingLabel(top: 8, left: 12, bottom: 8, right: 12) 
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.numberOfLines = 0
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure the label hugs its contents tightly
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    /// Constrains the toast label to the bottom center of the view.
    /// - Parameters:
    ///   - toast: The toast label to constrain.
    ///   - view: The parent view.
    private func constrainToast(_ toast: UILabel, in view: UIView) {
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }

    /// Performs a fade-in / delay / fade-out animation sequence.
    /// - Parameter toast: The toast label to animate.
    private func animateToastInAndOut(_ toast: UILabel) {
        UIView.animate(withDuration: 0.5, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2, options: .curveEaseOut, animations: {
                toast.alpha = 0
            }) { _ in
                // Cleanup: remove the toast from the view hierarchy once finished
                toast.removeFromSuperview()
            }
        }
    }
}

// MARK: - Events & Data Models

private extension ToastComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Displays the toast message.
        case show
    }

    /// The data structure expected in the message from the web side.
    struct MessageData: Decodable {
        /// The toast message text.
        let message: String
    }
}

// MARK: - UI Helpers

/// A custom `UILabel` that allows for padding around its text.
class PaddingLabel: UILabel {
    private var topInset: CGFloat
    private var leftInset: CGFloat
    private var bottomInset: CGFloat
    private var rightInset: CGFloat

    /// Initializes a padding label with specified insets.
    init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.topInset = top
        self.leftInset = left
        self.bottomInset = bottom
        self.rightInset = right
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        self.topInset = 0
        self.leftInset = 0
        self.bottomInset = 0
        self.rightInset = 0
        super.init(coder: aDecoder)
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
}
