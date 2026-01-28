////
////  LocationComponentController.swift
////  Demo
////
////  Created by rishabh on 16/07/25.
////
//
//import Foundation
//import CoreLocation
//
//final class LocationManagerController: NSObject, CLLocationManagerDelegate {
//    private let locationManager = CLLocationManager()
//    private let completion: (Result<CLLocation, Error>) -> Void
//    var didComplete: Bool = false
//
//    init(completion: @escaping (Result<CLLocation, Error>) -> Void) {
//        self.completion = completion
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        start()
//    }
//
//    func start() {
//        let status = CLLocationManager.authorizationStatus()
//
//        switch status {
//        case .notDetermined:
//            locationManager.requestWhenInUseAuthorization()
//        case .authorizedWhenInUse, .authorizedAlways:
//            locationManager.requestLocation()
//        case .denied, .restricted:
//            completion(.failure(LocationError.permissionDenied))
//        @unknown default:
//            completion(.failure(LocationError.unknown))
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let location = locations.first {
//            guard !didComplete else { return }
//            didComplete = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                        self.completion(.success(location))
//                    }
//        } else {
//            completion(.failure(LocationError.noLocation))
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        completion(.failure(error))
//    }
//
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        let status = manager.authorizationStatus
//        if status == .authorizedWhenInUse || status == .authorizedAlways {
//            manager.requestLocation()
//        } else if status == .denied || status == .restricted {
//            completion(.failure(LocationError.permissionDenied))
//        }
//    }
//
//    enum LocationError: LocalizedError {
//        case permissionDenied
//        case noLocation
//        case unknown
//
//        var errorDescription: String? {
//            switch self {
//            case .permissionDenied: return "Location permission denied"
//            case .noLocation: return "Failed to retrieve location"
//            case .unknown: return "Unknown location error"
//            }
//        }
//    }
//}
//
//
//
//
//
//  LocationManagerController.swift
//  Demo
//
//  Created by rishabh on 16/07/25.
//

import Foundation
import CoreLocation

final class LocationManagerController: NSObject {

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private let completion: (Result<CLLocation, Error>) -> Void
    private var didComplete = false

    // MARK: - Init

    init(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        start()
    }

    // MARK: - Start Flow

     func start() {
        handleAuthorization(locationManager.authorizationStatus)
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()

        case .denied, .restricted:
            completeOnce(.failure(LocationError.permissionDenied))

        @unknown default:
            completeOnce(.failure(LocationError.unknown))
        }
    }

    // MARK: - Completion Safety

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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorization(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.first else {
            completeOnce(.failure(LocationError.noLocation))
            return
        }

        completeOnce(.success(location))
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        completeOnce(.failure(error))
    }
}

// MARK: - Errors

extension LocationManagerController {

    enum LocationError: LocalizedError {
        case permissionDenied
        case noLocation
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
