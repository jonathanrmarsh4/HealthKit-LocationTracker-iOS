import Foundation
import UIKit
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
        case userId, timestamp, health, deviceInfo
        // Top-level location fields for server compatibility
        case latitude, longitude, accuracy, altitude, speed
    }

    // Custom encoding to flatten location data to top level
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(health, forKey: .health)
        try container.encode(deviceInfo, forKey: .deviceInfo)

        // Flatten location fields to top level as server expects
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encode(location.accuracy, forKey: .accuracy)
        try container.encode(location.altitude, forKey: .altitude)
        try container.encode(location.speed, forKey: .speed)
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

enum LocationStatus: Equatable {
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

// MARK: - Sync Configuration

struct SyncConfiguration: Codable {
    let locationInterval: TimeInterval // in minutes
    let healthKitInterval: TimeInterval // in minutes
    let syncOnAppOpen: Bool
    let notificationsEnabled: Bool
    let serverURL: String

    enum CodingKeys: String, CodingKey {
        case locationInterval = "location_polling_minutes"
        case healthKitInterval = "healthkit_sync_minutes"
        case syncOnAppOpen = "sync_on_app_open"
        case notificationsEnabled = "notifications_enabled"
        case serverURL = "server_url"
    }

    static var defaultConfig: SyncConfiguration {
        SyncConfiguration(
            locationInterval: 5,
            healthKitInterval: 180,
            syncOnAppOpen: true,
            notificationsEnabled: true,
            serverURL: "https://nodeserver-production-8388.up.railway.app"
        )
    }

    // Convert minutes to seconds for Timer usage
    var locationIntervalSeconds: TimeInterval {
        locationInterval * 60
    }

    var healthKitIntervalSeconds: TimeInterval {
        healthKitInterval * 60
    }
}

struct ServerStatusResponse: Codable {
    let status: String
    let device: String?
    let userId: String?
    let location: LocationInfo?
    let health: HealthInfo?
    let syncConfig: SyncConfigInfo?

    struct LocationInfo: Codable {
        let latitude: Double
        let longitude: Double
        let timestamp: String
    }

    struct HealthInfo: Codable {
        let steps: Int?
        let restingHeartRate: Int?
        let heartRateVariability: Double?
        let bloodOxygen: Double?
        let activeEnergy: Double?
        let distance: Double?
        let flightsClimbed: Int?
        let sleepDuration: TimeInterval?
    }

    struct SyncConfigInfo: Codable {
        let locationPolling: String
        let healthKitSync: String
        let syncOnAppOpen: Bool
        let notifications: Bool

        enum CodingKeys: String, CodingKey {
            case locationPolling = "location_polling"
            case healthKitSync = "healthkit_sync"
            case syncOnAppOpen = "sync_on_app_open"
            case notifications
        }

        // Parse "Every X minutes" or "Every X hours" into minutes
        func parseInterval(_ text: String) -> TimeInterval {
            let components = text.lowercased().components(separatedBy: " ")
            if let numberIndex = components.firstIndex(of: "every"),
               numberIndex + 1 < components.count,
               let value = Double(components[numberIndex + 1]) {
                if components.contains("hours") || components.contains("hour") {
                    return value * 60 // Convert hours to minutes
                } else if components.contains("minutes") || components.contains("minute") {
                    return value
                }
            }
            return 30 // Default fallback
        }

        func toSyncConfiguration(serverURL: String = SyncConfiguration.defaultConfig.serverURL) -> SyncConfiguration {
            return SyncConfiguration(
                locationInterval: parseInterval(locationPolling),
                healthKitInterval: parseInterval(healthKitSync),
                syncOnAppOpen: syncOnAppOpen,
                notificationsEnabled: notifications,
                serverURL: serverURL
            )
        }
    }
}
