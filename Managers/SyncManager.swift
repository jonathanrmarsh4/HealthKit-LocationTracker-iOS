import Foundation
import BackgroundTasks
import CoreLocation

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
        let payload = SyncPayload(
            userId: userId,
            timestamp: Date(),
            health: health,
            location: location,
            deviceInfo: DeviceInfo.current
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
    
    private func uploadPayload(_ payload: SyncPayload) async {
        do {
            guard let url = URL(string: serverURL) else {
                throw NSError(domain: "Sync", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "Sync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server error"])
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
