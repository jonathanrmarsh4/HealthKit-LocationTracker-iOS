import Foundation
import CoreLocation
import UIKit

// MARK: - Authentication

struct User: Codable {
    let id: String
    let email: String
    let createdAt: Date
}

// MARK: - Health Data

struct HealthDataPoint: Codable, Identifiable {
    var id: UUID {
        // Generate stable ID from timestamp
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", Int(timestamp.timeIntervalSince1970 * 1000) % 1000000000000))") ?? UUID()
    }

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

    init(timestamp: Date,
         steps: Int? = nil,
         heartRate: Int? = nil,
         restingHeartRate: Int? = nil,
         heartRateVariability: Double? = nil,
         bloodPressureSystolic: Int? = nil,
         bloodPressureDiastolic: Int? = nil,
         bloodOxygen: Double? = nil,
         activeEnergy: Double? = nil,
         distance: Double? = nil,
         flightsClimbed: Int? = nil,
         sleepDuration: TimeInterval? = nil,
         workoutDuration: TimeInterval? = nil,
         workoutType: String? = nil,
         workoutCalories: Double? = nil) {
        self.timestamp = timestamp
        self.steps = steps
        self.heartRate = heartRate
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.bloodPressureSystolic = bloodPressureSystolic
        self.bloodPressureDiastolic = bloodPressureDiastolic
        self.bloodOxygen = bloodOxygen
        self.activeEnergy = activeEnergy
        self.distance = distance
        self.flightsClimbed = flightsClimbed
        self.sleepDuration = sleepDuration
        self.workoutDuration = workoutDuration
        self.workoutType = workoutType
        self.workoutCalories = workoutCalories
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, steps, heartRate, restingHeartRate, heartRateVariability
        case bloodPressureSystolic, bloodPressureDiastolic, bloodOxygen
        case activeEnergy, distance, flightsClimbed
        case sleepDuration, workoutDuration, workoutType, workoutCalories
    }
}

struct LocationDataPoint: Codable, Identifiable {
    var id: UUID {
        // Generate stable ID from timestamp
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", Int(timestamp.timeIntervalSince1970 * 1000) % 1000000000000))") ?? UUID()
    }

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
    let settings: SyncSettings

    // Normal initializer for creating payloads in code
    init(userId: String, timestamp: Date, health: HealthDataPoint, location: LocationDataPoint, deviceInfo: DeviceInfo, settings: SyncSettings) {
        self.userId = userId
        self.timestamp = timestamp
        self.health = health
        self.location = location
        self.deviceInfo = deviceInfo
        self.settings = settings
    }

    enum CodingKeys: String, CodingKey {
        case userId, timestamp
        // Location fields at top level
        case latitude, longitude, accuracy, altitude, speed
        // Health fields at top level
        case steps, heartRate, restingHeartRate, heartRateVariability
        case bloodPressureSystolic, bloodPressureDiastolic, bloodOxygen
        case activeEnergy, distance, flightsClimbed
        case sleepDuration, workoutDuration, workoutType, workoutCalories
        // Device info at top level
        case deviceModel, osVersion, appVersion, isSimulator
        // Settings as nested object
        case settings
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode user and timestamp
        try container.encode(userId, forKey: .userId)
        try container.encode(timestamp, forKey: .timestamp)

        // Flatten location data to top level
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encode(location.accuracy, forKey: .accuracy)
        try container.encode(location.altitude, forKey: .altitude)
        try container.encode(location.speed, forKey: .speed)

        // Flatten health data to top level
        try container.encodeIfPresent(health.steps, forKey: .steps)
        try container.encodeIfPresent(health.heartRate, forKey: .heartRate)
        try container.encodeIfPresent(health.restingHeartRate, forKey: .restingHeartRate)
        try container.encodeIfPresent(health.heartRateVariability, forKey: .heartRateVariability)
        try container.encodeIfPresent(health.bloodPressureSystolic, forKey: .bloodPressureSystolic)
        try container.encodeIfPresent(health.bloodPressureDiastolic, forKey: .bloodPressureDiastolic)
        try container.encodeIfPresent(health.bloodOxygen, forKey: .bloodOxygen)
        try container.encodeIfPresent(health.activeEnergy, forKey: .activeEnergy)
        try container.encodeIfPresent(health.distance, forKey: .distance)
        try container.encodeIfPresent(health.flightsClimbed, forKey: .flightsClimbed)
        try container.encodeIfPresent(health.sleepDuration, forKey: .sleepDuration)
        try container.encodeIfPresent(health.workoutDuration, forKey: .workoutDuration)
        try container.encodeIfPresent(health.workoutType, forKey: .workoutType)
        try container.encodeIfPresent(health.workoutCalories, forKey: .workoutCalories)

        // Flatten device info to top level
        try container.encode(deviceInfo.deviceModel, forKey: .deviceModel)
        try container.encode(deviceInfo.osVersion, forKey: .osVersion)
        try container.encode(deviceInfo.appVersion, forKey: .appVersion)
        try container.encode(deviceInfo.isSimulator, forKey: .isSimulator)

        // Encode settings as nested object
        try container.encode(settings, forKey: .settings)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        userId = try container.decode(String.self, forKey: .userId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)

        // Reconstruct location from flattened data
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        let accuracy = try container.decode(Double.self, forKey: .accuracy)
        let altitude = try container.decode(Double.self, forKey: .altitude)
        let speed = try container.decode(Double.self, forKey: .speed)

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let clLocation = CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: accuracy,
            verticalAccuracy: accuracy,
            timestamp: timestamp
        )
        location = LocationDataPoint(location: coordinate, clLocation: clLocation)

        // Reconstruct health from flattened data
        health = HealthDataPoint(
            timestamp: timestamp,
            steps: try container.decodeIfPresent(Int.self, forKey: .steps),
            heartRate: try container.decodeIfPresent(Int.self, forKey: .heartRate),
            restingHeartRate: try container.decodeIfPresent(Int.self, forKey: .restingHeartRate),
            heartRateVariability: try container.decodeIfPresent(Double.self, forKey: .heartRateVariability),
            bloodPressureSystolic: try container.decodeIfPresent(Int.self, forKey: .bloodPressureSystolic),
            bloodPressureDiastolic: try container.decodeIfPresent(Int.self, forKey: .bloodPressureDiastolic),
            bloodOxygen: try container.decodeIfPresent(Double.self, forKey: .bloodOxygen),
            activeEnergy: try container.decodeIfPresent(Double.self, forKey: .activeEnergy),
            distance: try container.decodeIfPresent(Double.self, forKey: .distance),
            flightsClimbed: try container.decodeIfPresent(Int.self, forKey: .flightsClimbed),
            sleepDuration: try container.decodeIfPresent(TimeInterval.self, forKey: .sleepDuration),
            workoutDuration: try container.decodeIfPresent(TimeInterval.self, forKey: .workoutDuration),
            workoutType: try container.decodeIfPresent(String.self, forKey: .workoutType),
            workoutCalories: try container.decodeIfPresent(Double.self, forKey: .workoutCalories)
        )

        // Reconstruct device info from flattened data
        deviceInfo = DeviceInfo(
            deviceModel: try container.decode(String.self, forKey: .deviceModel),
            osVersion: try container.decode(String.self, forKey: .osVersion),
            appVersion: try container.decode(String.self, forKey: .appVersion),
            isSimulator: try container.decode(Bool.self, forKey: .isSimulator)
        )

        // Decode settings (use default if not present for backwards compatibility)
        settings = try container.decodeIfPresent(SyncSettings.self, forKey: .settings) ?? .default
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

struct SyncSettings: Codable {
    let locationPollIntervalMinutes: Int
    let healthkitSyncIntervalHours: Int
    let syncOnAppOpen: Bool
    let notificationsEnabled: Bool
    let locationPrecision: String

    enum CodingKeys: String, CodingKey {
        case locationPollIntervalMinutes = "location_poll_interval_minutes"
        case healthkitSyncIntervalHours = "healthkit_sync_interval_hours"
        case syncOnAppOpen = "sync_on_app_open"
        case notificationsEnabled = "notifications_enabled"
        case locationPrecision = "location_precision"
    }

    static var `default`: SyncSettings {
        SyncSettings(
            locationPollIntervalMinutes: 5,
            healthkitSyncIntervalHours: 3,
            syncOnAppOpen: true,
            notificationsEnabled: true,
            locationPrecision: "best"
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

enum SyncStatus: Equatable {
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
