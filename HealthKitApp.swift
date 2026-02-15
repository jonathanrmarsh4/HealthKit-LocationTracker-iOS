import SwiftUI
import UserNotifications

@main
struct HealthKitTrackerApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var healthManager = HealthKitManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var syncManager = SyncManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                DashboardView()
                    .environmentObject(authManager)
                    .environmentObject(healthManager)
                    .environmentObject(locationManager)
                    .environmentObject(syncManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
    
    init() {
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
