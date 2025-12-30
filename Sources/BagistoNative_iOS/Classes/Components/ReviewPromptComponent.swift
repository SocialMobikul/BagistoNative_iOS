import HotwireNative
import StoreKit

import struct HotwireNative.Message

final class ReviewPromptComponent: BridgeComponent {
    override class var name: String { "review-prompt" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .prompt:
            promptForReview()
        }
    }

    private func promptForReview() {
        if let scene = viewController?.view.window?.windowScene {
            if #available(iOS 16.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

private extension ReviewPromptComponent {
    enum Event: String {
        case prompt
    }
}
