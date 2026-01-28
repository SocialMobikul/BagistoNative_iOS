import HotwireNative
import UIKit
import AVFoundation

/// A bridge component that handles barcode and QR code scanning.
/// This component responds to the "barcode" name from the web side.
final class BarcodeScannerComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "barcode" }

    // MARK: - Properties

    /// Reference to the scanner view controller to manage its lifecycle.
    private var scannerViewController: BarcodeScannerViewController?

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }
        
        switch event {
        case .start:
            presentScanner(for: message)
        }
    }

    // MARK: - Private Methods

    /// Presents the barcode scanner view controller.
    /// - Parameter message: The message that triggered the scanner.
    private func presentScanner(for message: Message) {
        guard let presenter = delegate?.destination as? UIViewController else { return }

        let scannerVC = BarcodeScannerViewController()
        
        // Callback handling for when a code is successfully scanned
        scannerVC.onScanComplete = { [weak self] result in
            scannerVC.dismiss(animated: true) {
                // Reply to the web side with the scanned code
                self?.reply(to: message.event, with: ["code": result])
            }
        }

        presenter.present(scannerVC, animated: true)
        scannerViewController = scannerVC
    }
}

// MARK: - Events

private extension BarcodeScannerComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Starts the barcode scanning process.
        case start
    }
}
