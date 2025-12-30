
import UIKit
import AVFoundation
import Vision

protocol MLSearchDelegate: AnyObject {
    func onSelected(data selected: String)
}

final class MLImageSearchViewModel: NSObject {

    weak var controller: MLImageSearchViewController?
    weak var delegate: MLSearchDelegate?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var suggestions: [String] = []
    private var isExpanded = false

    // MARK: - Setup
    func prepareView() {
        guard let controller else { return }

        controller.suggestionView.isUserInteractionEnabled = true
        controller.stackView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(toggleSuggestions))
        )

        controller.tableView.delegate = self
        controller.tableView.dataSource = self
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
            self.captureSession.sessionPreset = .medium

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "vision.queue"))

            if self.captureSession.canAddOutput(output) {
                self.captureSession.addOutput(output)
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
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // MARK: - UI
    @objc private func toggleSuggestions() {
        guard let controller else { return }
        isExpanded.toggle()

        if isExpanded {
            let maxHeight = controller.view.bounds.height / 3
            let height = min(CGFloat((suggestions.count + 1) * 40), maxHeight)
            controller.expandSuggestionView(height: height)
        } else {
            controller.collapseSuggestionView()
        }
    }

    private func updateSuggestions(_ items: [String]) {
        let newItems = items.filter { !suggestions.contains($0) }
        guard !newItems.isEmpty else { return }

        suggestions.append(contentsOf: newItems)

        DispatchQueue.main.async {
            self.controller?.tableView.reloadData()
            self.controller?.updateSuggestionCount(self.suggestions.count)
        }
    }
}

// MARK: - Vision
extension MLImageSearchViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let controller
        else { return }

        if controller.searchType == .image {
            let request = VNClassifyImageRequest { [weak self] req, _ in
                let results = (req.results as? [VNClassificationObservation])?
                    .prefix(3)
                    .map { $0.identifier }
                self?.updateSuggestions(results ?? [])
            }

            try? VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
                .perform([request])
        } else {
            let request = VNRecognizeTextRequest { [weak self] req, _ in
                let results = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                self?.updateSuggestions(results ?? [])
            }

            try? VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
                .perform([request])
        }
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
