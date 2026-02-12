import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutConfirm = false
    @State private var locationInterval: Double = 5
    @State private var healthKitInterval: Double = 180
    @State private var syncOnAppOpen: Bool = true
    @State private var notificationsEnabled: Bool = true
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("")
                    }
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                    .opacity(0) // Placeholder for centering
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .overlay(
                    Divider()
                        .background(Color.white.opacity(0.1)),
                    alignment: .bottom
                )
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Account Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Account")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                SettingRow(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    value: authManager.currentUser?.email ?? "N/A"
                                )
                                
                                Divider()
                                    .overlay(Color.white.opacity(0.1))
                                
                                SettingRow(
                                    icon: "calendar",
                                    title: "Member Since",
                                    value: {
                                        let formatter = DateFormatter()
                                        formatter.dateStyle = .medium
                                        return formatter.string(from: authManager.currentUser?.createdAt ?? Date())
                                    }()
                                )
                            }
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // App Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("App")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                SettingRow(
                                    icon: "info.circle.fill",
                                    title: "App Version",
                                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                                )
                                
                                Divider()
                                    .overlay(Color.white.opacity(0.1))
                                
                                SettingRow(
                                    icon: "iphone",
                                    title: "Device",
                                    value: UIDevice.current.name
                                )
                                
                                Divider()
                                    .overlay(Color.white.opacity(0.1))
                                
                                SettingRow(
                                    icon: "gear",
                                    title: "OS Version",
                                    value: UIDevice.current.systemVersion
                                )
                            }
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // Sync Settings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sync Settings")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)

                            VStack(spacing: 16) {
                                // Location Interval
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.green)
                                            .frame(width: 20)

                                        Text("Location Sync")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Text("Every \(Int(locationInterval)) min")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                                    }

                                    Slider(value: $locationInterval, in: 1...60, step: 1)
                                        .tint(.green)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)

                                // HealthKit Interval
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.red)
                                            .frame(width: 20)

                                        Text("HealthKit Sync")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Text("Every \(Int(healthKitInterval)) min")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                                    }

                                    Slider(value: $healthKitInterval, in: 5...360, step: 5)
                                        .tint(.red)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)

                                // Sync on App Open
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                                        .frame(width: 20)

                                    Text("Sync on App Open")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Toggle("", isOn: $syncOnAppOpen)
                                        .tint(Color(red: 0, green: 0.8, blue: 1))
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)

                                // Save Button
                                Button {
                                    Task {
                                        await saveSettings()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Save Sync Settings")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.2, green: 0.8, blue: 0.8),
                                                Color(red: 0.1, green: 0.6, blue: 0.9)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Data Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data & Sync")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    HStack(spacing: 12) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.red)
                                            .frame(width: 24)
                                        
                                        Text("Clear Cache")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(16)
                            }
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        
                        // Danger Zone
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Danger Zone")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red.opacity(0.6))
                                .padding(.horizontal, 16)
                            
                            Button {
                                showLogoutConfirm = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.backward.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.red)
                                    
                                    Text("Log Out")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Log Out", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        locationInterval = syncManager.syncConfig.locationInterval
        healthKitInterval = syncManager.syncConfig.healthKitInterval
        syncOnAppOpen = syncManager.syncConfig.syncOnAppOpen
        notificationsEnabled = syncManager.syncConfig.notificationsEnabled
    }

    private func saveSettings() async {
        let newConfig = SyncConfiguration(
            locationInterval: locationInterval,
            healthKitInterval: healthKitInterval,
            syncOnAppOpen: syncOnAppOpen,
            notificationsEnabled: notificationsEnabled
        )

        await syncManager.updateSyncConfiguration(newConfig)

        // Show success feedback
        print("✅ Settings saved")
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SyncManager.shared)
}
