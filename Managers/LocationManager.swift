import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    @Published var currentLocation: LocationDataPoint?
    @Published var locationStatus: LocationStatus = .unknown
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private var isBackgroundTaskRunning = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Meters
        checkLocationAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    private func checkLocationAuthorization() {
        let status = locationManager.authorizationStatus
        DispatchQueue.main.async {
            switch status {
            case .notDetermined:
                self.locationStatus = .unknown
            case .denied, .restricted:
                self.locationStatus = .denied
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationStatus = .enabled
                self.startUpdatingLocation()
            @unknown default:
                self.locationStatus = .unknown
            }
        }
    }
    
    // MARK: - Location Updates
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        if #available(iOS 15.0, *) {
            locationManager.startUpdatingHeading()
        }
        print("📍 Location tracking started")
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        if #available(iOS 15.0, *) {
            locationManager.stopUpdatingHeading()
        }
        print("📍 Location tracking stopped")
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let dataPoint = LocationDataPoint(
            location: location.coordinate,
            clLocation: location
        )
        
        DispatchQueue.main.async {
            self.currentLocation = dataPoint
            print("📍 Location updated: \(dataPoint.latitude), \(dataPoint.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationStatus = .error(error.localizedDescription)
            self.errorMessage = "Location error: \(error.localizedDescription)"
            print("❌ Location error: \(error)")
        }
    }
}
