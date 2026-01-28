import UIKit

/// A view controller that manages the camera for capturing images.
/// It handles camera presentation, image selection, and base64 encoding with compression.
final class ImageCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Callbacks

    /// Closure called when an image is captured or the process is cancelled.
    /// Returns a base64 encoded data URL string on success, or `nil` on failure/cancellation.
    var onImageCaptured: ((String?) -> Void)?

    // MARK: - Properties

    /// The system image picker controller configured for camera usage.
    private let imagePicker = UIImagePickerController()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = false

        // Present camera after a slight delay to ensure the view hierarchy is ready
        DispatchQueue.main.async {
            self.present(self.imagePicker, animated: true)
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    /// Called when the user has finished taking a photo.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            onImageCaptured?(nil)
            return
        }

        // Apply compression to the image to keep the data size manageable
        // Attempts to keep the file size under 2MB
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)

        let maxFileSize = 2 * 1024 * 1024 // 2MB threshold

        while let data = imageData, data.count > maxFileSize && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        guard let finalImageData = imageData else {
            onImageCaptured?(nil)
            return
        }

        // Convert the final image data to a base64 encoded data URL string
        let base64String = finalImageData.base64EncodedString()
        let fullDataURL = "data:image/jpeg;base64,\(base64String)"
        onImageCaptured?(fullDataURL)
    }

    /// Called when the user cancels the camera interaction.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true)
        onImageCaptured?(nil)
    }

    // MARK: - UI Configuration

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
