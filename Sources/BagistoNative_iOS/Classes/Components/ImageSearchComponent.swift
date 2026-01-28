import UIKit
import HotwireNative

/// A bridge component that handles image capture for visual search.
/// This component responds to the "imagesearch" name from the web side.
final class ImageSearchComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "imagesearch" }

    // MARK: - Properties

    /// Reference to the image capture view controller to manage its lifecycle.
    private var captureController: ImageCaptureViewController?

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .start:
            presentImageCapture(for: message)
        }
    }

    // MARK: - Private Methods

    /// Presents the image capture view controller.
    /// - Parameter message: The message that triggered the image capture.
    private func presentImageCapture(for message: Message) {
        guard let presenter = delegate?.destination as? UIViewController else { return }

        let controller = ImageCaptureViewController()
        
        // Callback handling for when an image is captured and converted to base64
        controller.onImageCaptured = { [weak self] base64 in
            controller.dismiss(animated: true) {
                if let base64 = base64 {
                    // Success: Send the base64 encoded image to the web side
                    self?.reply(to: message.event, with: ["imageBase64": base64])
                } else {
                    // Failure: Inform the web side about the error
                    self?.reply(to: message.event, with: ["error": "Image capture failed"])
                }
            }
        }

        presenter.present(controller, animated: true)
        captureController = controller
    }
}

// MARK: - Events

private extension ImageSearchComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Starts the image capture process.
        case start
    }
}
