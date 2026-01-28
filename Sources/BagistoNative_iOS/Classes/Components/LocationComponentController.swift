import Foundation
import CoreLocation

/// A helper class that manages the process of requesting the user's current location.
/// It handles authorization state changes and ensures a single completion call.
final class LocationManagerController: NSObject {

    // MARK: - Properties

    /// The system's location manager.
    private let locationManager = CLLocationManager()
    
    /// The completion closure to call when the location is found or an error occurs.
    private let completion: (Result<CLLocation, Error>) -> Void
    
    /// A flag to ensure the completion closure is only called once.
    private var didComplete = false

    // MARK: - Init

    /// Initializes a new location manager controller.
    /// - Parameter completion: The closure to call with the location result.
    init(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        start()
    }

    // MARK: - Start Flow

    /// Begins the location request flow, checking for authorization first.
     func start() {
        handleAuthorization(locationManager.authorizationStatus)
    }

    /// Handles different `CLAuthorizationStatus` states.
    /// - Parameter status: The current authorization status.
    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            // Request permission if not yet determined
            locationManager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            // Request the current location if authorized
            locationManager.requestLocation()

        case .denied, .restricted:
            // Inform about permission denial
            completeOnce(.failure(LocationError.permissionDenied))

        @unknown default:
            completeOnce(.failure(LocationError.unknown))
        }
    }

    // MARK: - Completion Safety

    /// Ensures the completion closure is called exactly once on the main thread.
    /// - Parameter result: The location result or error.
    private func completeOnce(_ result: Result<CLLocation, Error>) {
        guard !didComplete else { return }
        didComplete = true

        DispatchQueue.main.async {
            self.completion(result)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManagerController: CLLocationManagerDelegate {

    /// Called when the authorization status changes.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorization(manager.authorizationStatus)
    }

    /// Called when new locations are available.
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.first else {
            completeOnce(.failure(LocationError.noLocation))
            return
        }

        completeOnce(.success(location))
    }

    /// Called when the location manager fails to retrieve a location.
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        completeOnce(.failure(error))
    }
}

// MARK: - Errors

extension LocationManagerController {
    /// Custom error types for the LocationManagerController.
    enum LocationError: LocalizedError {
        /// The user denied location permissions.
        case permissionDenied
        /// No location data could be retrieved.
        case noLocation
        /// An unknown error occurred.
        case unknown

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission denied"
            case .noLocation:
                return "Failed to retrieve location"
            case .unknown:
                return "Unknown location error"
            }
        }
    }
}
