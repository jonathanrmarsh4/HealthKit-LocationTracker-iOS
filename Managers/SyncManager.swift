import Foundation
import BackgroundTasks
import UIKit

class SyncManager: NSObject, ObservableObject {
    static let shared = SyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var lastLocationSyncDate: Date?
    @Published var lastHealthKitSyncDate: Date?
    @Published var offlineQueue: [SyncPayload] = []
    @Published var syncConfig: SyncConfiguration = .defaultConfig

    private var locationSyncTimer: Timer?
    private var healthKitSyncTimer: Timer?
    private let queue = DispatchQueue(label: "com.healthkit.sync")
    private let fileManager = FileManager.default

    // Computed properties for server endpoints
    private var serverURL: String {
        return syncConfig.serverURL + "/location"
    }

    private var statusURL: String {
        return syncConfig.serverURL + "/status"
    }
    
    override init() {
        super.init()
        setupBackgroundTask()
        restoreOfflineQueue()

        // Fetch configuration from backend, then start timers
        Task {
            await fetchSyncConfiguration()
            await MainActor.run {
                scheduleSyncTimers()
            }
        }
    }

    deinit {
        locationSyncTimer?.invalidate()
        healthKitSyncTimer?.invalidate()
    }
    
    // MARK: - Configuration Management

    func fetchSyncConfiguration() async {
        do {
            // Get current user ID
            guard let userId = try? loadUserId() else {
                print("⚠️ No user ID, using default sync config")
                await MainActor.run {
                    self.syncConfig = .defaultConfig
                }
                return
            }

            // Fetch user-specific configuration from backend
            guard var urlComponents = URLComponents(string: statusURL) else { return }
            urlComponents.queryItems = [URLQueryItem(name: "userId", value: userId)]
            guard let url = urlComponents.url else { return }

            let (data, _) = try await URLSession.shared.data(from: url)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let statusResponse = try decoder.decode(ServerStatusResponse.self, from: data)

            if let syncConfigInfo = statusResponse.syncConfig {
                await MainActor.run {
                    // Preserve the current serverURL when updating config from backend
                    self.syncConfig = syncConfigInfo.toSyncConfiguration(serverURL: self.syncConfig.serverURL)
                    print("✅ Fetched user-specific sync config: Location every \(Int(syncConfig.locationInterval))min, HealthKit every \(Int(syncConfig.healthKitInterval))min")
                }
            }
        } catch {
            print("⚠️ Failed to fetch sync config, using defaults: \(error.localizedDescription)")
            await MainActor.run {
                self.syncConfig = .defaultConfig
            }
        }
    }

    func updateSyncConfiguration(_ newConfig: SyncConfiguration) async {
        // Update local config
        await MainActor.run {
            self.syncConfig = newConfig
        }

        // Inform backend of new configuration
        await sendConfigurationToBackend(newConfig)

        // Reschedule timers with new intervals
        await MainActor.run {
            scheduleSyncTimers()
        }
    }

    private func sendConfigurationToBackend(_ config: SyncConfiguration) async {
        // Send user-specific configuration update to backend so it can adjust its polling
        do {
            guard let userId = try? loadUserId() else {
                print("⚠️ No user ID, cannot send config to backend")
                return
            }

            guard let url = URL(string: serverURL) else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let configPayload: [String: Any] = [
                "type": "config_update",
                "userId": userId,
                "location_interval_minutes": config.locationInterval,
                "healthkit_interval_minutes": config.healthKitInterval,
                "sync_on_app_open": config.syncOnAppOpen,
                "notifications_enabled": config.notificationsEnabled,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: configPayload)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ User-specific configuration sent to backend")
            }
        } catch {
            print("⚠️ Failed to send config to backend: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync Scheduling

    func scheduleSyncTimers() {
        // Cancel existing timers
        locationSyncTimer?.invalidate()
        healthKitSyncTimer?.invalidate()

        // Schedule location sync timer
        locationSyncTimer = Timer.scheduledTimer(
            withTimeInterval: syncConfig.locationIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            Task {
                await self?.performLocationSync()
            }
        }
        if let timer = locationSyncTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        print("⏱️ Location sync timer scheduled (every \(Int(syncConfig.locationInterval)) minutes)")

        // Schedule HealthKit sync timer
        healthKitSyncTimer = Timer.scheduledTimer(
            withTimeInterval: syncConfig.healthKitIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            Task {
                await self?.performHealthKitSync()
            }
        }
        if let timer = healthKitSyncTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        print("⏱️ HealthKit sync timer scheduled (every \(Int(syncConfig.healthKitInterval)) minutes)")

        // Schedule background tasks for when app is not active
        scheduleBackgroundTask()
    }

    // Keep this method for backward compatibility
    func scheduleSyncTimer() {
        scheduleSyncTimers()
    }
    
    func performManualSync() async {
        // Perform both location and HealthKit sync
        await performLocationSync()
        await performHealthKitSync()
    }

    // MARK: - Core Sync Logic

    func syncHealthAndLocation(health: HealthDataPoint, location: LocationDataPoint, userId: String) async {
        let payload = SyncPayload(
            userId: userId,
            timestamp: Date(),
            health: health,
            location: location,
            deviceInfo: DeviceInfo.current
        )

        await performSync(with: payload)
    }

    private func performLocationSync() async {
        print("📍 Performing location sync...")
        let location = LocationManager.shared.currentLocation ?? LocationDataPoint(
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            clLocation: CLLocation(latitude: 0, longitude: 0)
        )

        guard let userId = try? loadUserId() else {
            print("⚠️ No user ID for location sync")
            return
        }

        // Send location-only payload (no health data)
        let payload = SyncPayload(
            userId: userId,
            timestamp: Date(),
            health: nil, // Location syncs don't include health data
            location: location,
            deviceInfo: DeviceInfo.current
        )

        await uploadPayload(payload, syncType: .location)
    }

    private func performHealthKitSync() async {
        // Check if app is in background - HealthKit queries fail in background
        let isBackground = await MainActor.run {
            UIApplication.shared.applicationState == .background
        }

        if isBackground {
            print("⏭️ Skipping HealthKit sync - app in background (iOS limitation)")
            return
        }

        print("❤️ Performing HealthKit sync...")
        await HealthKitManager.shared.fetchHealthData()

        let health = HealthKitManager.shared.healthData
        let location = LocationManager.shared.currentLocation ?? LocationDataPoint(
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            clLocation: CLLocation(latitude: 0, longitude: 0)
        )

        guard let userId = try? loadUserId() else {
            print("⚠️ No user ID for HealthKit sync")
            return
        }

        let payload = SyncPayload(
            userId: userId,
            timestamp: Date(),
            health: health,
            location: location,
            deviceInfo: DeviceInfo.current
        )

        await uploadPayload(payload, syncType: .healthKit)
    }

    private enum SyncType {
        case location
        case healthKit
        case combined
    }
    
    private func performSync(with payload: SyncPayload? = nil) async {
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Fetch current data if no payload provided
            var payloadToSync = payload
            if payload == nil {
                // Get data from managers
                let health = HealthKitManager.shared.healthData
                let location = LocationManager.shared.currentLocation ?? LocationDataPoint(
                    location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    clLocation: CLLocation(latitude: 0, longitude: 0)
                )
                
                guard let userId = try? self.loadUserId() else {
                    DispatchQueue.main.async {
                        self.syncStatus = .error("No user ID")
                    }
                    return
                }
                
                payloadToSync = SyncPayload(
                    userId: userId,
                    timestamp: Date(),
                    health: health,
                    location: location,
                    deviceInfo: DeviceInfo.current
                )
            }
            
            guard let finalPayload = payloadToSync else {
                DispatchQueue.main.async {
                    self.syncStatus = .error("No data to sync")
                }
                return
            }
            
            Task {
                await self.uploadPayload(finalPayload)
            }
        }
    }
    
    private func uploadPayload(_ payload: SyncPayload, syncType: SyncType = .combined) async {
        do {
            print("🌐 Attempting sync to: \(serverURL)")

            guard let url = URL(string: serverURL) else {
                print("❌ Invalid server URL: \(serverURL)")
                throw NSError(domain: "Sync", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ No HTTP response received")
                throw NSError(domain: "Sync", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response from server"])
            }

            print("📡 Server response: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("❌ Server returned status \(httpResponse.statusCode): \(responseBody)")
                throw NSError(domain: "Sync", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
            }

            DispatchQueue.main.async {
                let now = Date()
                self.lastSyncDate = now

                switch syncType {
                case .location:
                    self.lastLocationSyncDate = now
                    print("✅ Location sync successful")
                case .healthKit:
                    self.lastHealthKitSyncDate = now
                    print("✅ HealthKit sync successful")
                case .combined:
                    self.lastLocationSyncDate = now
                    self.lastHealthKitSyncDate = now
                    print("✅ Combined sync successful")
                }

                self.syncStatus = .success(now)
                self.offlineQueue.removeAll()
                try? self.saveOfflineQueue()

                // Reschedule background task after successful sync
                self.scheduleBackgroundTask()
            }
        } catch {
            // Add to offline queue
            addToOfflineQueue(payload)

            DispatchQueue.main.async {
                self.syncStatus = .error(error.localizedDescription)
                print("❌ Sync failed (\(syncType)) to \(self.serverURL)")
                print("   Error: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("   Domain: \(nsError.domain), Code: \(nsError.code)")
                }
            }
        }
    }
    
    // MARK: - Offline Queue Management
    
    private func addToOfflineQueue(_ payload: SyncPayload) {
        queue.async {
            DispatchQueue.main.async {
                self.offlineQueue.append(payload)
                try? self.saveOfflineQueue()
                print("📦 Payload added to offline queue")
            }
        }
    }
    
    private func saveOfflineQueue() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(offlineQueue)
        
        let url = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("offline_queue.json")
        try data.write(to: url)
    }
    
    private func restoreOfflineQueue() {
        queue.async {
            let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("offline_queue.json")
            
            guard let url = url, let data = try? Data(contentsOf: url) else { return }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let queue = try? decoder.decode([SyncPayload].self, from: data) {
                DispatchQueue.main.async {
                    self.offlineQueue = queue
                    print("📦 Offline queue restored: \(queue.count) items")
                }
            }
        }
    }
    
    // MARK: - Background Tasks

    private func setupBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.healthkit.sync", using: nil) { task in
            self.handleBackgroundSync(task as! BGProcessingTask)
        }
    }

    private func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: "com.healthkit.sync")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        // Use the shorter interval (location) for background task scheduling
        let nextInterval = min(syncConfig.locationIntervalSeconds, syncConfig.healthKitIntervalSeconds)
        request.earliestBeginDate = Date(timeIntervalSinceNow: nextInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Background task scheduled for \(Int(nextInterval / 60)) minutes from now")
        } catch {
            print("❌ Failed to schedule background task: \(error.localizedDescription)")
        }
    }

    private func handleBackgroundSync(_ task: BGProcessingTask) {
        print("🔄 Background sync triggered")

        // Schedule next background task
        scheduleBackgroundTask()

        // Set expiration handler
        task.expirationHandler = {
            print("⚠️ Background task expired")
            task.setTaskCompleted(success: false)
        }

        // Perform sync based on what's due
        Task {
            let now = Date()

            // Check if location sync is due
            if let lastLocationSync = lastLocationSyncDate {
                let timeSinceLastLocation = now.timeIntervalSince(lastLocationSync)
                if timeSinceLastLocation >= syncConfig.locationIntervalSeconds {
                    await performLocationSync()
                }
            } else {
                await performLocationSync()
            }

            // SKIP HealthKit sync in background - HealthKit queries fail when app is not active
            // HealthKit will sync when app becomes active via sync-on-app-open
            print("⏭️ Skipping HealthKit sync in background (iOS limitation)")

            task.setTaskCompleted(success: true)
            print("✅ Background sync completed (location only)")
        }
    }
    
    // MARK: - User ID Management
    
    private func loadUserId() throws -> String? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser") else {
            return nil
        }
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: data)
        return user.id
    }
}

// Helper to get CLLocation import
import CoreLocation
