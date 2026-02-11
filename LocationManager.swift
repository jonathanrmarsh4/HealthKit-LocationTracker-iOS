import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    let manager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    var completionHandler: ((Double?, Double?, String?) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestAuthorization() {
        // Request "Always" authorization for background location updates
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            manager.requestAlwaysAndWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Request upgrade to "Always"
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("✅ Location authorization: Always")
            startUpdatingLocation()
        case .denied, .restricted:
            print("❌ Location authorization denied")
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = CLLocationManager.authorizationStatus()
        print("Location authorization status: \(status.rawValue)")
        
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startUpdatingLocation()
        }
    }
    
    private func startUpdatingLocation() {
        print("📍 Starting location updates...")
        manager.startUpdatingLocation()
    }
    
    func getCurrentLocation(completion: @escaping (Double?, Double?, String?) -> Void) {
        completionHandler = completion
        
        if let location = currentLocation {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            completion(location.latitude, location.longitude, timestamp)
        } else {
            // Request update if we don't have current location
            manager.requestLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location.coordinate
            let timestamp = ISO8601DateFormatter().string(from: location.timestamp)
            
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            completionHandler?(location.coordinate.latitude, location.coordinate.longitude, timestamp)
            completionHandler = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        
        // Return best estimate with current time
        if let location = currentLocation {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            completionHandler?(location.latitude, location.longitude, timestamp)
        } else {
            completionHandler?(nil, nil, nil)
        }
        completionHandler = nil
    }
}
