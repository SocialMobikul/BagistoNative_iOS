import UIKit
import HotwireNative

final class ImageSearchComponent: BridgeComponent {
    override class var name: String { "imagesearch" }

    private var captureController: ImageCaptureViewController?

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .start:
            presentImageCapture(for: message)
            break
      
        }
    }

    private func presentImageCapture(for message: Message) {
        guard let presenter = delegate?.destination as? UIViewController else { return }

        let controller = ImageCaptureViewController()
        controller.onImageCaptured = { [weak self] base64 in
            controller.dismiss(animated: true) {
                if let base64 = base64 {
                    self?.reply(to: message.event, with: ["imageBase64": base64])
                } else {
                    self?.reply(to: message.event, with: ["error": "Image capture failed"])
                }
            }
        }

        presenter.present(controller, animated: true)
        captureController = controller
    }
}

private extension ImageSearchComponent {
    enum Event: String {
        case start
    }
}
