import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private let serverURLKey = "serverURL"

    @Published var serverURL: String {
        didSet {
            defaults.set(serverURL, forKey: serverURLKey)
            print("💾 Server URL saved: \(serverURL)")
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

        print("⚙️ AppSettings initialized with server URL: \(serverURL)")
    }

    func resetToDefaults() {
        serverURL = "https://nodeserver-production-8388.up.railway.app/location"
    }
}
