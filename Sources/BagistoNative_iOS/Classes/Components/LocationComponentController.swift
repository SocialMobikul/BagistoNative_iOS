//
//  LocationComponentController.swift
//  Demo
//
//  Created by rishabh on 16/07/25.
//

import Foundation
import CoreLocation

final class LocationManagerController: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let completion: (Result<CLLocation, Error>) -> Void
    var didComplete: Bool = false

    init(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        self.completion = completion
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(.failure(LocationError.permissionDenied))
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            guard !didComplete else { return }
            didComplete = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.completion(.success(location))
                    }
        } else {
            completion(.failure(LocationError.noLocation))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion(.failure(error))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            completion(.failure(LocationError.permissionDenied))
        }
    }

    enum LocationError: LocalizedError {
        case permissionDenied
        case noLocation
        case unknown

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "Location permission denied"
            case .noLocation: return "Failed to retrieve location"
            case .unknown: return "Unknown location error"
            }
        }
    }
}




