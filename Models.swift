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

// MARK: - Sync Data (matches server's expected JSON format)

struct SyncPayload: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: String
    let device: String
    let deviceModel: String
    let userId: String
    let altitude: Double
    let speed: Double
    let health: HealthPayload
    let settings: SyncSettings

    init(userId: String, location: LocationDataPoint, health: HealthDataPoint) {
        self.latitude = location.latitude
        self.longitude = location.longitude

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.timestamp = formatter.string(from: Date())

        self.device = "iPhone"
        var systemInfo = utsname()
        uname(&systemInfo)
        self.deviceModel = String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"

        self.userId = userId
        self.altitude = location.altitude
        self.speed = max(0, location.speed)
        self.health = HealthPayload(from: health)
        self.settings = SyncSettings.current
    }
}

struct HealthPayload: Codable {
    let steps: Int?
    let heartRate: Int?
    let restingHeartRate: Int?
    let heartRateVariability: Double?
    let bloodOxygen: Double?
    let activeEnergy: Double?
    let distance: Double?
    let flightsClimbed: Int?
    let sleepDuration: TimeInterval?

    init(from healthData: HealthDataPoint) {
        self.steps = healthData.steps
        self.heartRate = healthData.heartRate
        self.restingHeartRate = healthData.restingHeartRate
        self.heartRateVariability = healthData.heartRateVariability
        self.bloodOxygen = healthData.bloodOxygen
        self.activeEnergy = healthData.activeEnergy
        self.distance = healthData.distance
        self.flightsClimbed = healthData.flightsClimbed
        self.sleepDuration = healthData.sleepDuration
    }
}

struct SyncSettings: Codable {
    let locationPollIntervalMinutes: Int
    let healthkitSyncIntervalHours: Int
    let syncOnAppOpen: Bool
    let notificationsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case locationPollIntervalMinutes = "location_poll_interval_minutes"
        case healthkitSyncIntervalHours = "healthkit_sync_interval_hours"
        case syncOnAppOpen = "sync_on_app_open"
        case notificationsEnabled = "notifications_enabled"
    }

    static var current: SyncSettings {
        SyncSettings(
            locationPollIntervalMinutes: 5,
            healthkitSyncIntervalHours: 3,
            syncOnAppOpen: true,
            notificationsEnabled: true
        )
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
