

import HotwireNative
import UIKit
import CoreLocation

final class LocationComponent: BridgeComponent {
    override class var name: String { "location" }

    private var locationController: LocationManagerController?

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }
    

        switch event {
        case .addLocationButton:
            locationController?.start()
            let action1 = UIAction { [weak self] _ in
               print("rethgdfg")
                self?.reply(
                    to: message.event,
                    with: [
                        "coordinates":[
                            "latitude": "",
                            "longituderty": ""
                        ]
                    ]
                )
            }
            let item1 = UIBarButtonItem(
                title: "",
                image: UIImage(systemName: "cart"),
                primaryAction: action1
            )
            
        
        let action2 = UIAction { [weak self] _ in
            self?.requestLocation(for: message)
        }
        let item2 = UIBarButtonItem(
            title: "",
            image: UIImage(systemName: "location"),
            primaryAction: action2
        )
            viewController?.navigationItem.rightBarButtonItems = [item2]
          break
        case .getLocation:
          
             requestLocation(for: message)
        }
    }
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }
    private func requestLocation(for message: Message) {
        locationController = LocationManagerController { [weak self] result in
            switch result {
            case .success(let location):
                print("location")
                print(location.coordinate.latitude)
                print(location.coordinate.longitude)
                self?.reply(
                    to: message.event,
                    with: [
                        "coordinates":[
                            "latitude": location.coordinate.latitude,
                            "longitude": location.coordinate.longitude
                        ]
                    ]
                )
            case .failure(let error):
                self?.reply(to: message.event, with: ["error": error.localizedDescription])
            }
        }

        locationController?.start()
       
    }
}

private extension LocationComponent {
    enum Event: String {
        case getLocation
        case addLocationButton
    }
}


