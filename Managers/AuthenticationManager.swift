import Foundation
import Security

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private let keychainService = "com.healthkit.tracker"
    
    override init() {
        super.init()
        restoreSession()
    }
    
    func login(email: String, password: String) async {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
        
        // Simulate authentication - in production, call your backend
        do {
            // Create mock user
            let user = User(
                id: UUID().uuidString,
                email: email,
                createdAt: Date()
            )
            
            // Save to keychain
            try saveCredentials(email: email, password: password)
            try saveUser(user)
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoggedIn = true
                print("✅ User logged in: \(email)")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Login failed: \(error.localizedDescription)"
                print("❌ Login failed: \(error)")
            }
        }
    }
    
    func signup(email: String, password: String) async {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
        
        do {
            // Validate inputs
            guard email.contains("@") else {
                throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid email"])
            }
            guard password.count >= 6 else {
                throw NSError(domain: "Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Password too short"])
            }
            
            // Create user
            let user = User(
                id: UUID().uuidString,
                email: email,
                createdAt: Date()
            )
            
            try saveCredentials(email: email, password: password)
            try saveUser(user)
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoggedIn = true
                print("✅ User signed up: \(email)")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Signup failed: \(error.localizedDescription)"
                print("❌ Signup failed: \(error)")
            }
        }
    }
    
    func logout() {
        do {
            try deleteCredentials()
            try deleteUser()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isLoggedIn = false
                print("✅ User logged out")
            }
        } catch {
            print("❌ Logout failed: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func restoreSession() {
        if let user = try? loadUser() {
            self.currentUser = user
            self.isLoggedIn = true
            print("✅ Session restored for: \(user.email)")
        }
    }
    
    private func saveCredentials(email: String, password: String) throws {
        let credentials = "\(email):\(password)"
        guard let data = credentials.data(using: .utf8) else {
            throw NSError(domain: "Auth", code: 3)
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        try SecItemAdd(query as CFDictionary, nil).throwIfError()
    }
    
    private func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        try SecItemDelete(query as CFDictionary).throwIfError()
    }
    
    private func saveUser(_ user: User) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        UserDefaults.standard.set(data, forKey: "currentUser")
    }
    
    private func loadUser() throws -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser") else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(User.self, from: data)
    }
    
    private func deleteUser() throws {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}

extension OSStatus {
    func throwIfError() throws {
        guard self != errSecSuccess else { return }
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(self))
    }
}
