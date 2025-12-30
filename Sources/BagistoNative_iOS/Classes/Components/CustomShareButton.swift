import HotwireNative
import UIKit


final class MobikulShareButtonComponent: BridgeComponent {

override class var name: String { "share" }

private var viewController: UIViewController? {
delegate?.destination as? UIViewController
}

// MARK: - Receive messages
override func onReceive(message: Message) {
    print(message.jsonData)
    let jsonString = message.jsonData // ✅ No optional unwrapping needed
    if let data = jsonString.data(using: .utf8) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print(json)

                let type = json["type"] as? String
                let metadata = json["metadata"] as? [String: Any]
                switch type {
                           case "share":
                    handleConnect(message: message)
                           case "cart":
                               handleClick(message: message)

                           default:
                               print("Unhandled type: \(type)")
                           }
            }
        } catch {
            print("JSON parsing error: \(error)")
        }
    }


guard let event = Event(rawValue: message.event) else {
print("Unknown event: \(message.event)")
return
}

}

// MARK: - Handle connect
private func handleConnect(message: Message) {
guard let data: MessageData = message.data() else {
print("Invalid data in connect")
return
}

print("Handle connect type: \(data.type ?? "-"), url: \(data.url?.absoluteString ?? "-")")

switch data.type {
case "share":
addShareButton(url: data.url)

case "cart":
addCartButton(url: data.url)

default:
print("Unknown connect type: \(data.type ?? "-")")
}
}

// MARK: - Handle click
private func handleClick(message: Message) {
guard let data: MessageData = message.data() else {
print("Invalid data in click")
return
}

print("Handle click type: \(data.type ?? "-"), url: \(data.url?.absoluteString ?? "-")")

switch data.type {
case "cart":
    let action = UIAction { [unowned self] _ in
        self.reply(to: message.event)
    }

    let shareButton = UIBarButtonItem(
    title: "sergt",
    image: UIImage(systemName: "cart"),
    primaryAction: action
    )
    addNavItem(shareButton)

default:
print("Unknown click type: \(data.type ?? "-")")
}
}

// MARK: - Add nav bar buttons
private func addShareButton(url: URL?) {
guard let url else { return }

let action = UIAction { [unowned self] _ in
share(url)
}

let shareButton = UIBarButtonItem(
title: "Share",
image: UIImage(systemName: "square.and.arrow.up"),
primaryAction: action
)

addNavItem(shareButton)
}

private func addCartButton(url: URL?) {
let action = UIAction { [unowned self] _ in
openCart(url)
}

let cartButton = UIBarButtonItem(
title: "Cart",
image: UIImage(systemName: "cart"),
primaryAction: action
)

addNavItem(cartButton)
}

private func addNavItem(_ item: UIBarButtonItem) {
var items = viewController?.navigationItem.rightBarButtonItems ?? []
items.append(item)
viewController?.navigationItem.rightBarButtonItems = items
}

// MARK: - Actions
private func share(_ url: URL) {
let activityViewController = UIActivityViewController(
activityItems: [url],
applicationActivities: nil
)
viewController?.present(activityViewController, animated: true)
}

private func openCart(_ url: URL?) {
guard let url else { return }
print("Open Cart URL: \(url)")
UIApplication.shared.open(url)
}
}

// MARK: - Events

extension MobikulShareButtonComponent {
enum Event: String {
case connect
case click
}
}

// MARK: - Message data

struct MessageData: Decodable {
let urlString: String
let type: String?

var url: URL? {
URL(string: urlString)
}

enum CodingKeys: String, CodingKey {
case urlString = "url"
case type
}
}
