import UIKit

final class MLImageSearchViewController: UIViewController {

    // MARK: - Public
    var searchType: MLSearchType = .image
    var callBack: ((String) -> Void)?

    // MARK: - ViewModel
    private let viewModel = MLImageSearchViewModel()

    // MARK: - UI
    let closeBtn = UIButton(type: .system)
    let shutterButton = UIButton(type: .custom)
    let retakeButton = UIButton(type: .system)
    let searchButton = UIButton(type: .system)
    let capturedImageView = UIImageView()
    let cropOverlay = UIView()
    let suggestionView = UIView()
    let suggestionLabel = UILabel()
    let arrowImageView = UIImageView()
    let stackView = UIStackView()
    let tableView = UITableView()
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private let topLeftHandle = UIView()
    private let topRightHandle = UIView()
    private let bottomLeftHandle = UIView()
    private let bottomRightHandle = UIView()
    private let handleSize: CGFloat = 44 // Standard touch target

    private var suggestionViewHeightConstraint: NSLayoutConstraint!
    private var tableViewHeightConstraint: NSLayoutConstraint!
    private var selectionRect: CGRect = .zero
    private let maskLayer = CAShapeLayer()
    private let topLeftBracket = CAShapeLayer()
    private let topRightBracket = CAShapeLayer()
    private let bottomLeftBracket = CAShapeLayer()
    private let bottomRightBracket = CAShapeLayer()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !cropOverlay.isHidden {
            updateMaskLayer()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black

        // Close Button
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.setTitleColor(.white, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Shutter Button
        shutterButton.backgroundColor = .white
        shutterButton.setTitle("Take", for: .normal)
        shutterButton.setTitleColor(.black, for: .normal)
        shutterButton.layer.cornerRadius = 35
        shutterButton.layer.borderWidth = 5
        shutterButton.layer.borderColor = UIColor.lightGray.cgColor
        shutterButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)

        // Retake Button
        retakeButton.setTitle("Retake", for: .normal)
        retakeButton.setTitleColor(.white, for: .normal)
        retakeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        retakeButton.layer.cornerRadius = 8
        retakeButton.isHidden = true
        retakeButton.addTarget(self, action: #selector(retakeTapped), for: .touchUpInside)

        // Search Button
        searchButton.setTitle("Search", for: .normal)
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.backgroundColor = .systemBlue
        searchButton.layer.cornerRadius = 8
        searchButton.layer.borderWidth = 1
        searchButton.layer.borderColor = UIColor.white.cgColor
        searchButton.isHidden = true
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)

        // Captured Image View
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.clipsToBounds = true
        capturedImageView.isHidden = true

        // Crop Overlay
        cropOverlay.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        cropOverlay.layer.borderWidth = 1
        cropOverlay.backgroundColor = .clear
        cropOverlay.isHidden = true
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropPan(_:)))
        cropOverlay.addGestureRecognizer(panGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleCropPinch(_:)))
        cropOverlay.addGestureRecognizer(pinchGesture)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        cropOverlay.addGestureRecognizer(doubleTapGesture)

        [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle].forEach {
            $0.backgroundColor = .clear 
            $0.isUserInteractionEnabled = true
            view.addSubview($0) // Add to main view, not cropOverlay
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.isHidden = true
        }
        
        setupHandleGestures()
        setupBrackets()

        // Arrow Icon
        arrowImageView.image = UIImage(systemName: "chevron.up")
        arrowImageView.tintColor = .gray
        arrowImageView.contentMode = .scaleAspectFit

        // Suggestion Label
        suggestionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        suggestionLabel.text = "0 Suggestions"
        suggestionLabel.textColor = .label

        // StackView
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.addArrangedSubview(suggestionLabel)
        stackView.addArrangedSubview(arrowImageView)

        // Suggestion View
        suggestionView.backgroundColor = .secondarySystemBackground
        suggestionView.layer.cornerRadius = 12

        tableView.isHidden = true // Hide initially

        tableView.isHidden = true // Hide initially

        [capturedImageView, tableView, suggestionView, closeBtn, shutterButton, retakeButton, searchButton, activityIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        view.addSubview(cropOverlay)
        cropOverlay.translatesAutoresizingMaskIntoConstraints = true
        cropOverlay.isUserInteractionEnabled = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        suggestionView.addSubview(stackView)

        suggestionViewHeightConstraint = suggestionView.heightAnchor.constraint(equalToConstant: 40)

        NSLayoutConstraint.activate([
            // Captured Image View
            capturedImageView.topAnchor.constraint(equalTo: view.topAnchor),
            capturedImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            capturedImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            capturedImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Close Button
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Shutter Button
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: suggestionView.topAnchor, constant: -20),
            shutterButton.widthAnchor.constraint(equalToConstant: 70),
            shutterButton.heightAnchor.constraint(equalToConstant: 70),

            // Retake Button
            retakeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            retakeButton.bottomAnchor.constraint(equalTo: suggestionView.topAnchor, constant: -20),
            retakeButton.widthAnchor.constraint(equalToConstant: 80),
            retakeButton.heightAnchor.constraint(equalToConstant: 40),

            // Search Button
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchButton.bottomAnchor.constraint(equalTo: suggestionView.topAnchor, constant: -20),
            searchButton.widthAnchor.constraint(equalToConstant: 80),
            searchButton.heightAnchor.constraint(equalToConstant: 40),

            // Suggestion View
            suggestionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            suggestionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            suggestionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            suggestionViewHeightConstraint,

            // Table View
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: suggestionView.topAnchor, constant: -8),

            // StackView inside Suggestion View
            stackView.topAnchor.constraint(equalTo: suggestionView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: suggestionView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: suggestionView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: suggestionView.bottomAnchor, constant: -12),
            
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint.isActive = true
        
        view.bringSubviewToFront(closeBtn)
        view.bringSubviewToFront(shutterButton)
        view.bringSubviewToFront(retakeButton)
        view.bringSubviewToFront(searchButton)
        view.bringSubviewToFront(tableView)
        view.bringSubviewToFront(tableView)
        view.bringSubviewToFront(suggestionView)
        view.bringSubviewToFront(activityIndicator)
        
        // Ensure handles are on top
        [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle].forEach {
            view.bringSubviewToFront($0)
        }
        
        setupHandleConstraints()
        setupMaskLayer()
    }

    private func setupMaskLayer() {
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
        view.layer.insertSublayer(maskLayer, above: capturedImageView.layer)
    }

    private func updateMaskLayer() {
        let path = UIBezierPath(rect: view.bounds)
        let holePath = UIBezierPath(rect: cropOverlay.frame)
        path.append(holePath)
        maskLayer.path = path.cgPath
        updateBrackets()
        view.layoutIfNeeded() // Reposition handles constrained to cropOverlay
    }

    private func setupBrackets() {
        [topLeftBracket, topRightBracket, bottomLeftBracket, bottomRightBracket].forEach {
            $0.strokeColor = UIColor.white.cgColor
            $0.lineWidth = 4
            $0.fillColor = nil
            cropOverlay.layer.addSublayer($0)
        }
    }

    private func updateBrackets() {
        let size = cropOverlay.bounds.size
        let length: CGFloat = 20
        
        // Top Left
        let tlPath = UIBezierPath()
        tlPath.move(to: CGPoint(x: 0, y: length))
        tlPath.addLine(to: .zero)
        tlPath.addLine(to: CGPoint(x: length, y: 0))
        topLeftBracket.path = tlPath.cgPath
        
        // Top Right
        let trPath = UIBezierPath()
        trPath.move(to: CGPoint(x: size.width - length, y: 0))
        trPath.addLine(to: CGPoint(x: size.width, y: 0))
        trPath.addLine(to: CGPoint(x: size.width, y: length))
        topRightBracket.path = trPath.cgPath
        
        // Bottom Left
        let blPath = UIBezierPath()
        blPath.move(to: CGPoint(x: 0, y: size.height - length))
        blPath.addLine(to: CGPoint(x: 0, y: size.height))
        blPath.addLine(to: CGPoint(x: length, y: size.height))
        bottomLeftBracket.path = blPath.cgPath
        
        // Bottom Right
        let brPath = UIBezierPath()
        brPath.move(to: CGPoint(x: size.width - length, y: size.height))
        brPath.addLine(to: CGPoint(x: size.width, y: size.height))
        brPath.addLine(to: CGPoint(x: size.width, y: size.height - length))
        bottomRightBracket.path = brPath.cgPath
    }

    private func setupHandleConstraints() {
        NSLayoutConstraint.activate([
            topLeftHandle.centerXAnchor.constraint(equalTo: cropOverlay.leadingAnchor),
            topLeftHandle.centerYAnchor.constraint(equalTo: cropOverlay.topAnchor),
            topLeftHandle.widthAnchor.constraint(equalToConstant: handleSize),
            topLeftHandle.heightAnchor.constraint(equalToConstant: handleSize),

            topRightHandle.centerXAnchor.constraint(equalTo: cropOverlay.trailingAnchor),
            topRightHandle.centerYAnchor.constraint(equalTo: cropOverlay.topAnchor),
            topRightHandle.widthAnchor.constraint(equalToConstant: handleSize),
            topRightHandle.heightAnchor.constraint(equalToConstant: handleSize),

            bottomLeftHandle.centerXAnchor.constraint(equalTo: cropOverlay.leadingAnchor),
            bottomLeftHandle.centerYAnchor.constraint(equalTo: cropOverlay.bottomAnchor),
            bottomLeftHandle.widthAnchor.constraint(equalToConstant: handleSize),
            bottomLeftHandle.heightAnchor.constraint(equalToConstant: handleSize),

            bottomRightHandle.centerXAnchor.constraint(equalTo: cropOverlay.trailingAnchor),
            bottomRightHandle.centerYAnchor.constraint(equalTo: cropOverlay.bottomAnchor),
            bottomRightHandle.widthAnchor.constraint(equalToConstant: handleSize),
            bottomRightHandle.heightAnchor.constraint(equalToConstant: handleSize)
        ])
    }

    private func setupHandleGestures() {
        topLeftHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:))))
        topRightHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:))))
        bottomLeftHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:))))
        bottomRightHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:))))
    }

    private func setupViewModel() {
        viewModel.controller = self
        viewModel.delegate = self
        viewModel.prepareView()
        viewModel.startImageLabeling()
    }

    // MARK: - Helpers
    func stopLoader() {
        activityIndicator.stopAnimating()
        searchButton.isEnabled = true
        view.isUserInteractionEnabled = true
    }

    func expandSuggestionView(height: CGFloat) {
        tableViewHeightConstraint.constant = height
        UIView.animate(withDuration: 0.3) {
            self.suggestionView.layer.cornerRadius = 0
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
            self.view.layoutIfNeeded()
        }
    }

    func collapseSuggestionView() {
        tableViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.suggestionView.layer.cornerRadius = 12
            self.arrowImageView.transform = .identity
            self.view.layoutIfNeeded()
        }
    }

    func updateSuggestionCount(_ count: Int) {
        suggestionLabel.text = "\(count) Suggestions"
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func captureTapped() {
        viewModel.captureImage { [weak self] image in
            guard let self = self, let image = image else { return }
            self.capturedImageView.image = image
            self.showCapturedState(true)
        }
    }

    @objc private func retakeTapped() {
        showCapturedState(false)
        viewModel.startLivePreview()
    }

    @objc private func searchTapped() {
        guard let image = capturedImageView.image else { return }
        
        // UI Feedback
        activityIndicator.startAnimating()
        searchButton.isEnabled = false
        view.isUserInteractionEnabled = false
        
        // Calculate crop rect relative to image size
        let cropRect = calculateCropRect(for: image)
        guard let croppedImage = cropImage(image, to: cropRect) else { 
            stopLoader()
            return 
        }
        
        // 200ms delay for specific animation request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            self.viewModel.performML(on: croppedImage)
            
            // Visual feedback
            UIView.animate(withDuration: 0.2, animations: {
                self.cropOverlay.layer.borderColor = UIColor.systemGreen.cgColor
            }) { _ in
                UIView.animate(withDuration: 0.5) {
                    self.cropOverlay.layer.borderColor = UIColor.white.cgColor
                }
            }
        }
    }

    @objc private func handleCropPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        var newCenter = CGPoint(x: cropOverlay.center.x + translation.x, y: cropOverlay.center.y + translation.y)
        
        // Keep within max frame
        let maxFrame = getMaxCropFrame()
        let halfWidth = cropOverlay.bounds.width / 2
        let halfHeight = cropOverlay.bounds.height / 2
        
        newCenter.x = max(maxFrame.minX + halfWidth, min(newCenter.x, maxFrame.maxX - halfWidth))
        newCenter.y = max(maxFrame.minY + halfHeight, min(newCenter.y, maxFrame.maxY - halfHeight))
        
        cropOverlay.center = newCenter
        gesture.setTranslation(.zero, in: view)
        updateMaskLayer()
    }

    @objc private func handleResizePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view else { return }
        let translation = gesture.translation(in: view)
        let maxFrame = getMaxCropFrame()
        let minSize: CGFloat = 80
        
        var left = cropOverlay.frame.minX
        var top = cropOverlay.frame.minY
        var right = cropOverlay.frame.maxX
        var bottom = cropOverlay.frame.maxY
        
        switch handle {
        case topLeftHandle:
            left += translation.x
            top += translation.y
        case topRightHandle:
            right += translation.x
            top += translation.y
        case bottomLeftHandle:
            left += translation.x
            bottom += translation.y
        case bottomRightHandle:
            right += translation.x
            bottom += translation.y
        default: break
        }
        
        // Constraints
        left = max(maxFrame.minX, min(left, right - minSize))
        top = max(maxFrame.minY, min(top, bottom - minSize))
        right = min(maxFrame.maxX, max(right, left + minSize))
        bottom = min(maxFrame.maxY, max(bottom, top + minSize))
        
        cropOverlay.frame = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        updateMaskLayer()
        gesture.setTranslation(.zero, in: view)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let maxFrame = getMaxCropFrame()
        let isNearlyFull = abs(cropOverlay.frame.width - maxFrame.width) < 10 && abs(cropOverlay.frame.height - maxFrame.height) < 10
        
        UIView.animate(withDuration: 0.3) {
            if isNearlyFull {
                // Minimize to center square
                let side = min(maxFrame.width, maxFrame.height) * 0.5
                self.cropOverlay.frame = CGRect(
                    x: maxFrame.midX - side/2,
                    y: maxFrame.midY - side/2,
                    width: side,
                    height: side
                )
            } else {
                // Maximize to full screen
                self.cropOverlay.frame = maxFrame
            }
            self.updateMaskLayer()
        }
    }

    private func getMaxCropFrame() -> CGRect {
        let topPadding = view.safeAreaInsets.top + 60 // Below close button
        let bottomPadding = view.safeAreaInsets.bottom + 120 // Above suggestion view and buttons
        return CGRect(
            x: 20,
            y: topPadding,
            width: view.bounds.width - 40,
            height: view.bounds.height - topPadding - bottomPadding
        )
    }

    @objc private func handleCropPinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            let scale = gesture.scale
            let newSize = CGSize(width: cropOverlay.bounds.width * scale, height: cropOverlay.bounds.height * scale)
            
            // Limit size
            let minSize: CGFloat = 50
            let maxSize = min(view.bounds.width, view.bounds.height)
            
            if newSize.width > minSize && newSize.width < maxSize {
                cropOverlay.bounds = CGRect(origin: .zero, size: newSize)
                updateMaskLayer()
            }
            gesture.scale = 1.0
        }
    }

    private func showCapturedState(_ isCaptured: Bool) {
        capturedImageView.isHidden = !isCaptured
        cropOverlay.isHidden = !isCaptured
        retakeButton.isHidden = !isCaptured
        searchButton.isHidden = !isCaptured
        shutterButton.isHidden = isCaptured
        
        // Ensure drawer stays closed when entering captured state
        if isCaptured {
            tableView.isHidden = false 
            collapseSuggestionView()
            updateMaskLayer()
            maskLayer.isHidden = false
            view.bringSubviewToFront(tableView)
            view.bringSubviewToFront(suggestionView)
            
            [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle].forEach {
                $0.isHidden = false
                view.bringSubviewToFront($0)
            }
        } else {
            tableView.isHidden = true
            maskLayer.isHidden = true
            suggestionLabel.text = "0 Suggestions"
            [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle].forEach { $0.isHidden = true }
        }
        
        if isCaptured {
            // Start as full screen crop
            let maxFrame = getMaxCropFrame()
            cropOverlay.frame = maxFrame
            updateMaskLayer()
        }
    }

    private func calculateCropRect(for image: UIImage) -> CGRect {
        let viewSize = capturedImageView.bounds.size
        let imageSize = image.size
        
        let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        let offsetX = (scaledImageSize.width - viewSize.width) / 2
        let offsetY = (scaledImageSize.height - viewSize.height) / 2
        
        let cropRectInView = cropOverlay.frame
        
        let x = (cropRectInView.origin.x + offsetX) / scale
        let y = (cropRectInView.origin.y + offsetY) / scale
        let width = cropRectInView.width / scale
        let height = cropRectInView.height / scale
        
        // Since image is normalized, we can use these coordinates directly
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
        
        guard let fullCGImage = image.cgImage else { return nil }
        
        // Clip to image bounds to avoid nil return from cropping(to:)
        let imageRect = CGRect(x: 0, y: 0, width: CGFloat(fullCGImage.width), height: CGFloat(fullCGImage.height))
        let intersection = scaledRect.intersection(imageRect)
        
        guard !intersection.isEmpty, let cgImage = fullCGImage.cropping(to: intersection) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
    }
}

// MARK: - Delegate
extension MLImageSearchViewController: MLSearchDelegate {
    func onSelected(data selected: String) {
        viewModel.stopImageLabeling()
        dismiss(animated: true) {
            self.callBack?(selected)
        }
    }
}

enum MLSearchType {
    case image
    case text
}
