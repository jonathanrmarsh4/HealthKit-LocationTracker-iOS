import UIKit
import HealthKit
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var healthKitManager: HealthKitManager?
    var locationManager: LocationManager?
    var networkManager: NetworkManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize managers
        healthKitManager = HealthKitManager()
        locationManager = LocationManager()
        networkManager = NetworkManager(serverURL: "https://nodeserver-production-8388.up.railway.app")
        
        // Request HealthKit permissions
        healthKitManager?.requestAuthorization { success in
            if success {
                print("✅ HealthKit authorization granted")
            } else {
                print("❌ HealthKit authorization failed")
            }
        }
        
        // Request Location permissions
        locationManager?.requestAuthorization()
        
        // Schedule background task
        scheduleBackgroundTask()
        
        // Create simple UI
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Location & Health Tracker\n\nTracking active...\nData sent every 30 minutes"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -20)
        ])
        
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    private func scheduleBackgroundTask() {
        // Schedule to run every 30 minutes
        let request = BGAppRefreshTaskRequest(identifier: "com.health-tracker.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background task scheduled")
        } catch {
            print("❌ Failed to schedule background task: \(error)")
        }
    }
    
    // Called when app goes to background
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Trigger sync before going to background
        syncData()
        
        // Schedule next background refresh
        scheduleBackgroundTask()
    }
    
    // Called when app returns to foreground
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Sync data immediately
        syncData()
    }
    
    private func syncData() {
        print("📡 Syncing data...")
        
        guard let healthKit = healthKitManager,
              let location = locationManager,
              let network = networkManager else {
            return
        }
        
        // Get current location
        location.getCurrentLocation { (lat, lon, timestamp) in
            // Get health data
            healthKit.fetchTodayData { healthData in
                // Combine and send
                let payload: [String: Any] = [
                    "latitude": lat ?? 0,
                    "longitude": lon ?? 0,
                    "timestamp": timestamp ?? ISO8601DateFormatter().string(from: Date()),
                    "device": "iPhone",
                    "health": healthData
                ]
                
                network.sendData(payload) { success in
                    if success {
                        print("✅ Data sent successfully")
                    } else {
                        print("❌ Failed to send data")
                    }
                }
            }
        }
    }
}
