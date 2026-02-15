import Foundation
import BackgroundTasks

class SyncManager: NSObject, ObservableObject {
    static let shared = SyncManager()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var offlineQueue: [SyncPayload] = []
    
    private let serverURL = "https://nodeserver-production-8388.up.railway.app/location"
    private let syncInterval: TimeInterval = 30 * 60 // 30 minutes
    private var syncTimer: Timer?
    private let queue = DispatchQueue(label: "com.healthkit.sync")
    private let fileManager = FileManager.default
    
    override init() {
        super.init()
        setupBackgroundTask()
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
        print("⏱️ Sync timer scheduled (every \(Int(syncInterval / 60)) minutes)")
    }
    
    func performManualSync() async {
        await performSync()
    }
    
    // MARK: - Core Sync Logic

    func syncHealthAndLocation(health: HealthDataPoint, location: LocationDataPoint, userId: String) async {
        let payload = SyncPayload(userId: userId, location: location, health: health)
        await uploadPayload(payload)
    }

    private func performSync() async {
        await MainActor.run {
            self.syncStatus = .syncing
        }

        // Fetch fresh health data and await completion
        await HealthKitManager.shared.fetchHealthData()

        let health = await MainActor.run { HealthKitManager.shared.healthData }
        let location = await MainActor.run {
            LocationManager.shared.currentLocation ?? LocationDataPoint(
                location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                clLocation: CLLocation(latitude: 0, longitude: 0)
            )
        }

        guard let userId = try? loadUserId() else {
            await MainActor.run {
                self.syncStatus = .error("No user ID")
            }
            print("❌ Sync skipped: No user ID found")
            return
        }

        let payload = SyncPayload(userId: userId, location: location, health: health)

        print("🌐 Attempting sync to: \(serverURL)")
        print("📦 Payload health: steps=\(health.steps ?? 0), HR=\(health.heartRate ?? 0), distance=\(health.distance ?? 0)km")

        await uploadPayload(payload)
    }
    
    private func uploadPayload(_ payload: SyncPayload) async {
        do {
            var request = URLRequest(url: URL(string: serverURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(payload)
            request.httpBody = jsonData

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Request body: \(jsonString)")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Sync", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
            }

            print("📡 Server response: \(httpResponse.statusCode)")

            if let responseBody = String(data: data, encoding: .utf8) {
                print("📥 Response body: \(responseBody)")
            }

            guard httpResponse.statusCode == 200 else {
                throw NSError(domain: "Sync", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
            }

            await MainActor.run {
                self.lastSyncDate = Date()
                self.syncStatus = .success(Date())
                self.offlineQueue.removeAll()
                try? self.saveOfflineQueue()
                print("✅ HealthKit sync successful")
            }
        } catch {
            addToOfflineQueue(payload)

            await MainActor.run {
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
        let data = try JSONEncoder().encode(offlineQueue)
        let url = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("offline_queue.json")
        try data.write(to: url)
    }

    private func restoreOfflineQueue() {
        queue.async {
            let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("offline_queue.json")

            guard let url = url, let data = try? Data(contentsOf: url) else { return }

            if let restored = try? JSONDecoder().decode([SyncPayload].self, from: data) {
                DispatchQueue.main.async {
                    self.offlineQueue = restored
                    print("📦 Offline queue restored: \(restored.count) items")
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

// Helper to get CLLocation import
import CoreLocation
