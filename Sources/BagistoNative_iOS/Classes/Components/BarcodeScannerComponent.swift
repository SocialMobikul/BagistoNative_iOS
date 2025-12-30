import HotwireNative
import UIKit
import AVFoundation

final class BarcodeScannerComponent: BridgeComponent {
    override class var name: String { "barcode" }

    private var scannerViewController: BarcodeScannerViewController?

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }
        print("");
        switch event {
        case .start:
            presentScanner(for: message)
        }
    }

    private func presentScanner(for message: Message) {
        guard let presenter = delegate?.destination as? UIViewController else { return }

        let scannerVC = BarcodeScannerViewController()
        scannerVC.onScanComplete = { [weak self] result in
            scannerVC.dismiss(animated: true) {
        
                self?.reply(to: message.event, with: ["code": result])
            }
        }

        presenter.present(scannerVC, animated: true)
        scannerViewController = scannerVC
    }
}

private extension BarcodeScannerComponent {
    enum Event: String {
        case start
    }
}
