import SwiftUI
import UserNotifications

@main
struct HealthKitTrackerApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var healthManager = HealthKitManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var syncManager = SyncManager.shared
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    init() {
        requestNotificationPermissions()
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            print("📱 App entering background - scheduling background task")
            // Ensure background task is scheduled when app goes to background
            Task {
                await syncManager.performManualSync()
            }
        case .active:
            print("📱 App became active - resuming sync timer")
            // Refresh sync timer when app becomes active
            syncManager.scheduleSyncTimer()
        default:
            break
        }
    }
}
