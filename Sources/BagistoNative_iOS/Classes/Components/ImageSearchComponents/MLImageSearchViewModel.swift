
import UIKit
import AVFoundation
import Vision

protocol MLSearchDelegate: AnyObject {
    func onSelected(data selected: String)
}

final class MLImageSearchViewModel: NSObject, UIGestureRecognizerDelegate {

    weak var controller: MLImageSearchViewController?
    weak var delegate: MLSearchDelegate?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var suggestions: [String] = []
    private var isExpanded = false
    private var isLive = true

    // Vision model for image classification
    private lazy var imageLabelerModel: VNCoreMLModel? = {
        // Try to find the compiled model (.mlmodelc) in module bundle, then main bundle
        let modelURL = BagistoBundle.bundle.url(forResource: "FastViTT8F16", withExtension: "mlmodelc") ??
                      BagistoBundle.bundle.url(forResource: "FastViTT8F16", withExtension: "mlmodel") ??
                      Bundle.main.url(forResource: "FastViTT8F16", withExtension: "mlmodelc") ??
                      Bundle.main.url(forResource: "FastViTT8F16", withExtension: "mlmodel")

        guard let url = modelURL else {
            print("❌ FastViTT8F16 model not found in BagistoBundle or Bundle.main")
            print("📦 BagistoBundle path: \(BagistoBundle.bundle.bundlePath)")
            return nil
        }
        
        do {
            let model = try VNCoreMLModel(for: MLModel(contentsOf: url))
            print("✅ FastViTT8F16 Model loaded successfully from: \(url.lastPathComponent)")
            return model
        } catch {
            print("❌ Error loading CoreML model: \(error)")
            return nil
        }
    }()

    // MARK: - Setup
    func prepareView() {
        guard let controller else { return }

        controller.suggestionView.isUserInteractionEnabled = true
        controller.stackView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(toggleSuggestions))
        )

        controller.tableView.delegate = self
        controller.tableView.dataSource = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        controller.view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions
    @objc func handleBackgroundTap(_ sender: UITapGestureRecognizer) {
        if isExpanded {
            collapseSuggestionsView()
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let controller else { return false }
        
        // Ignore touches inside the suggestion view (header + table)
        if touch.view?.isDescendant(of: controller.suggestionView) == true {
            return false
        }
        if touch.view?.isDescendant(of: controller.tableView) == true {
            return false
        }
        
        // Ignore touches on buttons
        if touch.view is UIButton {
            return false
        }
        
        return true
    }

    // MARK: - Camera
    // MARK: - Camera
    func startImageLabeling() {
        guard let controller,
              let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            if self.captureSession.canAddOutput(photoOutput) {
                self.captureSession.addOutput(photoOutput)
            }

            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer?.frame = controller.view.bounds
                self.previewLayer?.videoGravity = .resizeAspectFill

                if let previewLayer = self.previewLayer {
                    controller.view.layer.insertSublayer(previewLayer, at: 0)
                }
            }

            // ✅ Start session on background thread
            self.captureSession.startRunning()
        }
    }


    func stopImageLabeling() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    func startLivePreview() {
        isLive = true
        suggestions.removeAll()
        controller?.updateSuggestionCount(0)
        controller?.tableView.reloadData()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func captureImage(completion: @escaping (UIImage?) -> Void) {
        self.photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private var photoCompletion: ((UIImage?) -> Void)?

    func performML(on image: UIImage) {
        guard let controller, let cgImage = image.cgImage else { return }
        
        suggestions.removeAll()
        var requests: [VNRequest] = []
        
        if controller.searchType == .image {
            // 1. Text Recognition Request
            let textRequest = VNRecognizeTextRequest { [weak self] req, _ in
                let results = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                self?.updateSuggestions(results ?? [])
            }
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = true
            requests.append(textRequest)

            // 2. Image Classification Request
            if let model = imageLabelerModel {
                let classifierRequest = VNCoreMLRequest(model: model) { [weak self] req, _ in
                    let results = (req.results as? [VNClassificationObservation])?
                        .prefix(10)
                        .map { $0.identifier.replacingOccurrences(of: "_", with: " ").capitalized }
                    self?.updateSuggestions(results ?? [])
                }
                requests.append(classifierRequest)
            } else {
                let defaultRequest = VNClassifyImageRequest { [weak self] req, _ in
                    let results = (req.results as? [VNClassificationObservation])?
                        .prefix(10)
                        .map { $0.identifier.replacingOccurrences(of: "_", with: " ").capitalized }
                    self?.updateSuggestions(results ?? [])
                }
                requests.append(defaultRequest)
            }
        } else {
            // Text only mode
            let textRequest = VNRecognizeTextRequest { [weak self] req, _ in
                let results = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                self?.updateSuggestions(results ?? [])
            }
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = true
            textRequest.recognitionLanguages = ["en"]
            requests.append(textRequest)
        }
        
        try? VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            .perform(requests)
    }

    // MARK: - UI
    @objc private func toggleSuggestions() {
        if isExpanded {
            collapseSuggestionsView()
        } else {
            expandSuggestionsView()
        }
    }

    private func expandSuggestionsView() {
        guard let controller else { return }
        isExpanded = true
        let maxHeight = controller.view.bounds.height / 3
        let itemCount = suggestions.isEmpty ? 1 : suggestions.count
        let height = min(CGFloat((itemCount + 1) * 44), maxHeight)
        controller.expandSuggestionView(height: height)
    }

    private func collapseSuggestionsView() {
        guard let controller else { return }
        isExpanded = false
        controller.collapseSuggestionView()
    }

    private func updateSuggestions(_ items: [String]) {
        let newItems = items.filter { !suggestions.contains($0) }
        
        if !newItems.isEmpty {
            suggestions.append(contentsOf: newItems)
        }

        DispatchQueue.main.async {
            self.controller?.stopLoader()
            self.controller?.tableView.reloadData()
            
            if let topResult = self.suggestions.first {
                self.controller?.updateSuggestionCount(self.suggestions.count)
                self.controller?.suggestionLabel.text = "Result: \(self.suggestions.count)"
                self.expandSuggestionsView()
            } else {
                self.controller?.updateSuggestionCount(0)
                self.controller?.suggestionLabel.text = "No Result Found"
            }
        }
    }
}

// MARK: - Vision
extension MLImageSearchViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation() else {
            photoCompletion?(nil)
            return
        }
        
        let image = UIImage(data: imageData)
        
        // Normalize orientation so CGImage matches UIImage.size
        let normalizedImage = image?.normalized()
        
        photoCompletion?(normalizedImage)
        isLive = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
}

extension UIImage {
    func normalized() -> UIImage? {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}

// MARK: - TableView
extension MLImageSearchViewModel: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = suggestions[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.onSelected(data: suggestions[indexPath.row])
    }
}
