import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private let serverURLKey = "serverURL"
    private let syncSettingsKey = "syncSettings"

    @Published var serverURL: String {
        didSet {
            defaults.set(serverURL, forKey: serverURLKey)
            print("💾 Server URL saved: \(serverURL)")
        }
    }

    @Published var syncSettings: SyncSettings {
        didSet {
            if let encoded = try? JSONEncoder().encode(syncSettings) {
                defaults.set(encoded, forKey: syncSettingsKey)
                print("💾 Sync settings saved: location=\(syncSettings.locationPollIntervalMinutes)min, health=\(syncSettings.healthkitSyncIntervalHours)hr")
            }
        }
    }

    private init() {
        // Default server URL
        let defaultURL = "https://nodeserver-production-8388.up.railway.app/location"
        self.serverURL = defaults.string(forKey: serverURLKey) ?? defaultURL

        // If it's the first time, save the default
        if defaults.string(forKey: serverURLKey) == nil {
            defaults.set(defaultURL, forKey: serverURLKey)
        }

        // Load sync settings
        if let data = defaults.data(forKey: syncSettingsKey),
           let settings = try? JSONDecoder().decode(SyncSettings.self, from: data) {
            self.syncSettings = settings
        } else {
            self.syncSettings = .default
            // Save default settings
            if let encoded = try? JSONEncoder().encode(SyncSettings.default) {
                defaults.set(encoded, forKey: syncSettingsKey)
            }
        }

        print("⚙️ AppSettings initialized with server URL: \(serverURL)")
        print("⚙️ Sync settings: location=\(syncSettings.locationPollIntervalMinutes)min, health=\(syncSettings.healthkitSyncIntervalHours)hr")
    }

    func resetToDefaults() {
        serverURL = "https://nodeserver-production-8388.up.railway.app/location"
        syncSettings = .default
    }
}
