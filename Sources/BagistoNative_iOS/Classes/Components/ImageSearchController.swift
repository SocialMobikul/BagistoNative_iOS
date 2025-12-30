import UIKit

final class ImageCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var onImageCaptured: ((String?) -> Void)?

    private let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = false

        // Present camera after slight delay to avoid black screen
        DispatchQueue.main.async {
            self.present(self.imagePicker, animated: true)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            onImageCaptured?(nil)
            return
        }

        // Compress image until under 2MB
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)

        let maxFileSize = 2 * 1024 * 1024 // 2MB

        while let data = imageData, data.count > maxFileSize && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        guard let finalImageData = imageData else {
            onImageCaptured?(nil)
            return
        }

        // Convert to base64 with prefix
        let base64String = finalImageData.base64EncodedString()
        let fullDataURL = "data:image/jpeg;base64,\(base64String)"
        onImageCaptured?(fullDataURL)
    }


    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true)
        onImageCaptured?(nil)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
