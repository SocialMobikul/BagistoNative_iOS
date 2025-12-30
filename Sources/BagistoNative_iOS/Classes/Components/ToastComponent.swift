
import HotwireNative
import UIKit

final class ToastComponent: BridgeComponent {
    override class var name: String { "toast" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .show:
            showToast(via: message)
        }
    }

    private func showToast(via message: Message) {
        guard let data: MessageData = message.data(), let viewController else { return }

        let toast = makeLabel(text: data.message)
        viewController.view.addSubview(toast)
        constrainToast(toast, in: viewController.view)
        animateToastInAndOut(toast)
    }

    private func makeLabel(text: String) -> UILabel {
        let label = PaddingLabel(top: 8, left: 12, bottom: 8, right: 12) // ✅ Padding for better look
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
        
        // ✅ Dynamic height adjustment
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    private func constrainToast(_ toast: UILabel, in view: UIView) {
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }

    private func animateToastInAndOut(_ toast: UILabel) {
        UIView.animate(withDuration: 0.5, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2, options: .curveEaseOut, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}

private extension ToastComponent {
    enum Event: String {
        case show
    }
}

private extension ToastComponent {
    struct MessageData: Decodable {
        let message: String
    }
}
class PaddingLabel: UILabel {
    private var topInset: CGFloat
    private var leftInset: CGFloat
    private var bottomInset: CGFloat
    private var rightInset: CGFloat

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
