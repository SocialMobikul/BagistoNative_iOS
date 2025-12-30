//
//  CartUpdateComponent.swift
//  Demo
//
//  Created by adnan on 23/07/25.
//

import Foundation
import HotwireNative
import UIKit

final class CartLoad: BridgeComponent {
    override class var name: String { "cartload" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        
//        print("rdghthnfghfghgf")
//        if let topVC = navigator?.rootViewController.topViewController {
//            print("Top VC: \(topVC)")
//
//            if let visitableView = (topVC as? HotwireWebViewController)?.visitableView {
//                let subviews = visitableView.subviews
//                for subview in subviews {
//                    print("Subview: \(subview)")
//                    if let activityIndicator = subview as? UIActivityIndicatorView {
//
//                            }
//                }
//            }
//            
//        }

        let jsonString = message.jsonData // ✅ No optional unwrapping needed
        if let data = jsonString.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print(json)
                    
//                    print(GlobalData.cartCount)
                    print(json["cart"] ?? 0)
                    print(message.jsonData)
//                    badgeLabel.text = "\(json["cart"] ?? 0)"
//                    if(badgeLabel.text) == "0" {
//                        badgeLabel.isHidden = true
//                    } else {
//                        badgeLabel.isHidden = false
//                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }
    }

 }

private extension CartLoad {
    enum Event: String {
        case show
    }
}

private extension CartLoad {
    struct MessageData: Decodable {
        let title: String
        let description: String?
        let destructive: Bool
        let confirm: String
        let dismiss: String

        var confirmActionStyle: UIAlertAction.Style { destructive ? .destructive : .default }
    }
}

