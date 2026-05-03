//
//  LocationManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    @Published var currentCountry: String?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationPermissionStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        // Check if location services are enabled system-wide
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled. Please enable them in Settings > Privacy & Security > Location Services."
            print("DEBUG: Location services disabled system-wide")
            return
        }
        
        switch locationPermissionStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location access for SmartPrice in Settings > Privacy & Security > Location Services."
            print("DEBUG: Location permission denied or restricted")
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    func getCurrentLocationString() -> String {
        if let city = currentCity, let country = currentCountry {
            return "\(city), \(country)"
        } else if let country = currentCountry {
            return country
        } else {
            return "Location not available"
        }
    }
    
    // MARK: - Private Methods
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to get location: \(error.localizedDescription)"
                    print("DEBUG: Reverse geocoding error: \(error)")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self?.errorMessage = "No location information available"
                    return
                }
                
                self?.currentCity = placemark.locality ?? placemark.administrativeArea
                self?.currentCountry = placemark.country
                
                print("DEBUG: Location updated - City: \(self?.currentCity ?? "Unknown"), Country: \(self?.currentCountry ?? "Unknown")")
                
                // Stop location updates after getting the location once
                self?.stopLocationUpdates()
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        reverseGeocode(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.errorMessage = "Location not available"
                    print("DEBUG: Location unknown - GPS unable to determine location")
                case .denied:
                    self.errorMessage = "Location access denied. Please enable location services in Settings."
                    print("DEBUG: Location access denied")
                case .network:
                    self.errorMessage = "Network error. Please check your internet connection."
                    print("DEBUG: Location network error")
                case .headingFailure:
                    self.errorMessage = "Unable to determine location direction."
                    print("DEBUG: Location heading failure")
                case .rangingUnavailable, .rangingFailure:
                    self.errorMessage = "Location ranging unavailable."
                    print("DEBUG: Location ranging error")
                default:
                    self.errorMessage = "Location error: \(error.localizedDescription)"
                    print("DEBUG: Other location error: \(clError.localizedDescription) (Code: \(clError.code.rawValue))")
                }
            } else {
                self.errorMessage = "Location error: \(error.localizedDescription)"
                print("DEBUG: Non-CLError location error: \(error)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("DEBUG: Location permission granted")
                self.startLocationUpdates()
            case .denied, .restricted:
                print("DEBUG: Location permission denied")
                self.errorMessage = "Location access denied. Please enable in Settings to use location-based currency detection."
            case .notDetermined:
                print("DEBUG: Location permission not determined")
            @unknown default:
                break
            }
        }
    }
}

