//
//  LocationManager.swift
//  WeatherApp
//
//  Created by ryan mota on 2025-02-24.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastKnownLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        switch manager.authorizationStatus {
        case .notDetermined:
            print("⚠️ Requesting location access")
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location authorized")
            manager.startUpdatingLocation()
        default:
            print("❌ Location access denied")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorizationStatus()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("❌ No valid location received")
            return
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        print("📍 New location received: \(latitude), \(longitude)")

        lastKnownLocation = location

        // Save location in UserDefaults (App Group)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.triosRM.WeatherApp") {
            sharedDefaults.set([latitude, longitude], forKey: "lastLocation")
            sharedDefaults.synchronize()
            print("✅ Location saved in UserDefaults")
        } else {
            print("❌ Failed to access shared UserDefaults")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Failed to get location: \(error.localizedDescription)")
    }
}
