import UIKit
import HealthKit
import CoreLocation
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Register background tasks
        SyncManager.shared.setupBackgroundTask()

        // Schedule initial background task
        scheduleBackgroundTask()

        print("✅ AppDelegate initialized - background tasks registered")

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
        Task {
            await SyncManager.shared.performManualSync()
        }

        // Schedule next background refresh
        scheduleBackgroundTask()
    }

    // Called when app returns to foreground
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Sync data immediately
        Task {
            await SyncManager.shared.performManualSync()
        }
    }
}
