import HotwireNative
import UIKit
import QuickLook

/// A bridge component that handles downloading files and previewing them using `QLPreviewController`.
/// This component responds to the "download" name from the web side.
final class FileViewerComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "download" }

    // MARK: - Properties

    /// The view controller that's currently displaying the bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    /// The local URL where the file has been downloaded.
    private var downloadedFileURL: URL?
    /// Reference to the activity indicator to show downloading progress.
    private var loader: UIActivityIndicatorView?

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .download:
            downloadAndViewFile(via: message)
        }
    }

    // MARK: - Private Methods

    /// Orchestrates the file download and presentation.
    /// - Parameter message: The message containing the download link.
    private func downloadAndViewFile(via message: Message) {
        // Extract the download link from the message's JSON data
        guard let data = message.jsonData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let linkString = json["downloadLink"] as? String,
              let url = URL(string: linkString) else {
            print("Invalid download link")
            return
        }

        // Show a loader on the main thread
        DispatchQueue.main.async {
            self.showLoader()
        }

        // Start the background download task
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
                // Ensure the destination is clear before moving the temp file
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)

                DispatchQueue.main.async {
                    self.hideLoader()
                    self.downloadedFileURL = destinationURL
                    // Present the QuickLook preview controller
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

    // MARK: - Loader Management

    /// Displays a large activity indicator in the center of the view.
    private func showLoader() {
        guard let vc = viewController else { return }

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.center = vc.view.center
        indicator.startAnimating()
        indicator.hidesWhenStopped = true
        vc.view.addSubview(indicator)
        loader = indicator
    }

    /// Stops and removes the activity indicator.
    private func hideLoader() {
        loader?.stopAnimating()
        loader?.removeFromSuperview()
        loader = nil
    }
}

// MARK: - Events

private extension FileViewerComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Triggers the file download process.
        case download
    }

    /// Data structure for messages related to file viewing.
    struct MessageData: Decodable {
        let url: String
    }
}

// MARK: - QLPreviewControllerDataSource

extension FileViewerComponent: QLPreviewControllerDataSource {
    /// Returns the number of items to preview.
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return downloadedFileURL != nil ? 1 : 0
    }

    /// Returns the preview item for the given index.
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return downloadedFileURL! as NSURL
    }
}
