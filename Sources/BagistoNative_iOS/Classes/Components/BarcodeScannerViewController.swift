
import UIKit
import AVFoundation

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var onScanComplete: ((String) -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private let cameraQueue = DispatchQueue(label: "camera.session.queue")

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        captureSession = AVCaptureSession()

        cameraQueue.async { [weak self] in
            guard let self else { return }

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  self.captureSession.canAddInput(videoInput) else {
                DispatchQueue.main.async { self.failed() }
                return
            }

            self.captureSession.beginConfiguration()

            self.captureSession.addInput(videoInput)

            let metadataOutput = AVCaptureMetadataOutput()
            guard self.captureSession.canAddOutput(metadataOutput) else {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { self.failed() }
                return
            }

            self.captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .qr, .code128, .upce]

            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.frame = self.view.layer.bounds
                self.previewLayer.videoGravity = .resizeAspectFill
                self.view.layer.addSublayer(self.previewLayer)
            }

            // ✅ Start capture session on background queue
            self.captureSession.startRunning()
        }
    }

    
    func failed() {
        let alert = UIAlertController(title: "Scanning Not Supported", message: "Your device does not support scanning.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
        captureSession = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onScanComplete?(stringValue)
        } else {
            dismiss(animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
