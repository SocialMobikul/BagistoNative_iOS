import HotwireNative
import UIKit

class ThemeComponent: BridgeComponent {
    override static var name: String { "thememode" }

    private var window: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first
    }

    override func onReceive(message: Message) {
        guard let data: MessageData = message.data() else { return }
                let jsonString = message.jsonData // ✅ No optional unwrapping needed
                if let data = jsonString.data(using: .utf8) {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print(json)
                            if let mode = json["mode"] as? String {
                                 if mode == ("dark") {
                                     self.window?.overrideUserInterfaceStyle = .dark
                                 } else if  mode == ("light") {
                                     self.window?.overrideUserInterfaceStyle = .light
                                }
                            }
                        }
                    } catch {
                        print("JSON parsing error: \(error)")
                    }
                }

                
             
        }
 
}

private extension ThemeComponent {
    struct MessageData: Decodable {
        let theme: Theme?
    }
}

private extension ThemeComponent {
    enum Theme: String, Decodable {
        case light
        case dark
    }
}
