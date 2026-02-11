import Foundation
import BackgroundTasks
import CoreLocation

class SyncManager: NSObject, ObservableObject {
    static let shared = SyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var offlineQueue: [SyncPayload] = []

    private var syncTimer: Timer?
    private let queue = DispatchQueue(label: "com.healthkit.sync")
    private let fileManager = FileManager.default
    private let appSettings = AppSettings.shared

    // Computed property to get current sync interval from settings
    private var syncInterval: TimeInterval {
        // Convert hours to seconds for HealthKit sync interval
        return TimeInterval(appSettings.syncSettings.healthkitSyncIntervalHours * 3600)
    }

    override init() {
        super.init()
        scheduleSyncTimer()
        restoreOfflineQueue()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Sync Scheduling
    
    func scheduleSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performSync()
            }
        }
        let hours = Int(syncInterval / 3600)
        let minutes = Int((syncInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            print("⏱️ Sync timer scheduled (every \(hours)h \(minutes)m)")
        } else {
            print("⏱️ Sync timer scheduled (every \(minutes) minutes)")
        }
    }

    // Call this when settings change to update the timer
    func updateSyncInterval() {
        scheduleSyncTimer()
    }
    
    func performManualSync() async {
        await performSync()
    }
    
    // MARK: - Core Sync Logic
    
    func syncHealthAndLocation(health: HealthDataPoint, location: LocationDataPoint, userId: String) async {
        let payload = SyncPayload(
            userId: userId,
            timestamp: Date(),
            health: health,
            location: location,
            deviceInfo: DeviceInfo.current,
            settings: appSettings.syncSettings
        )

        await performSync(with: payload)
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

                // Create default location if not available
                let defaultCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                let defaultCLLocation = CLLocation(
                    coordinate: defaultCoordinate,
                    altitude: 0,
                    horizontalAccuracy: -1,
                    verticalAccuracy: -1,
                    timestamp: Date()
                )

                let location = LocationManager.shared.currentLocation ?? LocationDataPoint(
                    location: defaultCoordinate,
                    clLocation: defaultCLLocation
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
                    deviceInfo: DeviceInfo.current,
                    settings: appSettings.syncSettings
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
    
    private func uploadPayload(_ payload: SyncPayload) async {
        do {
            let serverURL = appSettings.serverURL
            print("🌐 Syncing to server: \(serverURL)")

            guard let url = URL(string: serverURL) else {
                throw NSError(domain: "Sync", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL: \(serverURL)"])
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(payload)

            if let jsonData = request.httpBody, let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Sending payload: \(jsonString.prefix(200))...")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Sync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }

            print("📡 Server response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("❌ Server error (\(httpResponse.statusCode)): \(responseBody)")
                throw NSError(domain: "Sync", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Server error (\(httpResponse.statusCode))",
                    "statusCode": httpResponse.statusCode,
                    "responseBody": responseBody
                ])
            }
            
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                self.syncStatus = .success(Date())
                self.offlineQueue.removeAll()
                try? self.saveOfflineQueue()
                print("✅ Sync successful")
            }
        } catch {
            // Add to offline queue
            addToOfflineQueue(payload)
            
            DispatchQueue.main.async {
                self.syncStatus = .error(error.localizedDescription)
                print("❌ Sync failed: \(error)")
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

    func setupBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.healthkit.sync", using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                print("❌ Background task is not a BGProcessingTask")
                task.setTaskCompleted(success: false)
                return
            }
            self.handleBackgroundSync(processingTask)
        }
    }
    
    private func handleBackgroundSync(_ task: BGProcessingTask) {
        scheduleSyncTimer()
        
        Task {
            await performSync()
            task.setTaskCompleted(success: true)
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
