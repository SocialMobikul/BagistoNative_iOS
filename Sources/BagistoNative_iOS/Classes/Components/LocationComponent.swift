import HotwireNative
import UIKit
import CoreLocation

/// A bridge component that handles location-related requests from the web view.
/// It can request the current location and add a location-triggering button to the navigation bar.
/// This component responds to the "location" name from the web side.
final class LocationComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "location" }

    // MARK: - Properties

    /// Reference to the location controller to manage location updates.
    private var locationController: LocationManagerController?

    /// The view controller that's currently displaying the bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .addLocationButton:
            setupLocationButton(for: message)
        case .getLocation:
            requestLocation(for: message)
        }
    }

    // MARK: - Private Methods

    /// Configures a button in the navigation bar that triggers a location request when tapped.
    /// - Parameter message: The message that requested the button.
    private func setupLocationButton(for message: Message) {
        let action = UIAction { [weak self] _ in
            self?.requestLocation(for: message)
        }
        let item = UIBarButtonItem(
            title: "",
            image: UIImage(systemName: "location"),
            primaryAction: action
        )
        viewController?.navigationItem.rightBarButtonItems = [item]
    }

    /// Requests the current location using `LocationManagerController`.
    /// - Parameter message: The original message that requested the location.
    private func requestLocation(for message: Message) {
        locationController = LocationManagerController { [weak self] result in
            switch result {
            case .success(let location):
                // Success: Reply with latitude and longitude
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
                // Failure: Reply with error description
                self?.reply(to: message.event, with: ["error": error.localizedDescription])
            }
        }

        locationController?.start()
    }
}

// MARK: - Events

private extension LocationComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Requests the current location immediately.
        case getLocation
        /// Adds a location button to the navigation bar.
        case addLocationButton
    }
}
