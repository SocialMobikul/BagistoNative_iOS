
import HotwireNative
import UIKit
import QuickLook

final class FileViewerComponent: BridgeComponent {
    override class var name: String { "download" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    private var downloadedFileURL: URL?
    private var loader: UIActivityIndicatorView?

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .download:
            downloadAndViewFile(via: message)
        }
    }

    private func downloadAndViewFile(via message: Message) {
        print(message.jsonData)

        guard let data = message.jsonData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let linkString = json["downloadLink"] as? String,
              let url = URL(string: linkString) else {
            print("Invalid download link")
            return
        }

        // Show loader before starting download
        DispatchQueue.main.async {
            self.showLoader()
        }

        let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempURL, response, error) in
            guard let self = self, let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self?.hideLoader()
                }
                print("Download error: \(error?.localizedDescription ?? "unknown error")")
                return
            }

            let fileManager = FileManager.default
            let filename = response?.suggestedFilename ?? url.lastPathComponent
            let destinationURL = fileManager.temporaryDirectory.appendingPathComponent(filename)

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)

                DispatchQueue.main.async {
                    self.hideLoader()
                    self.downloadedFileURL = destinationURL
                    let previewController = QLPreviewController()
                    previewController.dataSource = self
                    self.viewController?.present(previewController, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.hideLoader()
                }
                print("File move error: \(error)")
            }
        }

        task.resume()
    }

    private func showLoader() {
        guard let vc = viewController else { return }

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.center = vc.view.center
        indicator.startAnimating()
        indicator.hidesWhenStopped = true
        vc.view.addSubview(indicator)
        loader = indicator
    }

    private func hideLoader() {
        loader?.stopAnimating()
        loader?.removeFromSuperview()
        loader = nil
    }
}

private extension FileViewerComponent {
    enum Event: String {
        case download
    }

    struct MessageData: Decodable {
        let url: String
    }
}

extension FileViewerComponent: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return downloadedFileURL != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return downloadedFileURL! as NSURL
    }
}
