import Foundation
import CoreLocation

// MARK: - Authentication

struct User: Codable {
    let id: String
    let email: String
    let createdAt: Date
}

// MARK: - Health Data

struct HealthDataPoint: Codable, Identifiable {
    let id: UUID = UUID()
    let timestamp: Date
    
    var steps: Int?
    var heartRate: Int?
    var restingHeartRate: Int?
    var heartRateVariability: Double?
    var bloodPressureSystolic: Int?
    var bloodPressureDiastolic: Int?
    var bloodOxygen: Double?
    var activeEnergy: Double?
    var distance: Double?
    var flightsClimbed: Int?
    var sleepDuration: TimeInterval?
    var workoutDuration: TimeInterval?
    var workoutType: String?
    var workoutCalories: Double?
    
    enum CodingKeys: String, CodingKey {
        case timestamp, steps, heartRate, restingHeartRate, heartRateVariability
        case bloodPressureSystolic, bloodPressureDiastolic, bloodOxygen
        case activeEnergy, distance, flightsClimbed
        case sleepDuration, workoutDuration, workoutType, workoutCalories
    }
}

struct LocationDataPoint: Codable, Identifiable {
    let id: UUID = UUID()
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let altitude: Double
    let speed: Double
    
    init(location: CLLocationCoordinate2D, clLocation: CLLocation) {
        self.timestamp = Date()
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.accuracy = clLocation.horizontalAccuracy
        self.altitude = clLocation.altitude
        self.speed = clLocation.speed
    }
}

// MARK: - Sync Data

struct SyncPayload: Codable {
    let userId: String
    let timestamp: Date
    let health: HealthDataPoint
    let location: LocationDataPoint
    let deviceInfo: DeviceInfo
    
    enum CodingKeys: String, CodingKey {
        case userId, timestamp, health, location, deviceInfo
    }
}

struct DeviceInfo: Codable {
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let isSimulator: Bool
    
    static var current: DeviceInfo {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"
        
        return DeviceInfo(
            deviceModel: modelCode,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            isSimulator: ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
        )
    }
}

// MARK: - UI State

struct HealthStatCard {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: String
}

enum SyncStatus {
    case idle
    case syncing
    case success(Date)
    case error(String)
    
    var description: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .success(let date):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Synced \(formatter.string(from: date))"
        case .error(let error):
            return "Sync failed: \(error)"
        }
    }
}

enum LocationStatus {
    case unknown
    case denied
    case requestingAlways
    case enabled
    case error(String)
    
    var description: String {
        switch self {
        case .unknown:
            return "Checking..."
        case .denied:
            return "Permission Denied"
        case .requestingAlways:
            return "Requesting..."
        case .enabled:
            return "Active"
        case .error(let error):
            return "Error: \(error)"
        }
    }
}
