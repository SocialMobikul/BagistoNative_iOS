import HotwireNative
import UIKit

final class NavButtonComponent: BridgeComponent {
    override class var name: String { "nav-buttono" }

    private var buttons: [String: UIBarButtonItem] = [:]

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .add:
           let jsonString = message.jsonData // ✅ No optional unwrapping needed
            if let data = jsonString.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print(json)

                        let url = json["url"] as? String
                        let action = UIAction { [weak self] _ in
                            guard let url = URL(string: url ?? "") else { return }
                            self?.visit(url)
                        }
                        let item = UIBarButtonItem(
                            title: "",
                            image: UIImage(systemName: "cart"),
                            primaryAction: action
                        )
                        buttons["cart"] = item
                        var items = viewController?.navigationItem.rightBarButtonItems ?? []
                        items.append(item)
                        viewController?.navigationItem.rightBarButtonItems = items
                         
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
            }
            

        case .remove:
            if let data: ButtonData = message.data(), let item = buttons[data.type] {
                viewController?.navigationItem.rightBarButtonItems?.removeAll(where: { $0 == item })
                buttons.removeValue(forKey: data.type)
            }
        }
    }

    private func visit(_ url: URL) {
        // Safe cast to VisitableDelegate
        if let delegate = delegate as? VisitableDelegate {
            delegate.visit(url: url, options: VisitOptions(action: .advance))
        }
    }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    enum Event: String {
        case add, remove
    }

    struct ButtonData: Decodable {
        let type: String
        let title: String
        let url: String
        let iosImage: String
        let androidImage: String
    }
}
protocol VisitableDelegate: BridgingDelegate {
    func visit(url: URL, options: VisitOptions)
}
