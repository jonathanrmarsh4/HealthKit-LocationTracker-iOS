import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appSettings = AppSettings.shared

    @State private var showLogoutConfirm = false
    @State private var editingServerURL = false
    @State private var tempServerURL = ""

    // Sync settings
    @State private var locationPollInterval = 5
    @State private var healthkitSyncInterval = 3
    @State private var syncOnAppOpen = true
    @State private var notificationsEnabled = true
    @State private var locationPrecision = "best"

    let locationIntervalOptions = [1, 5, 10, 15, 30]
    let healthIntervalOptions = [1, 2, 3, 6, 12, 24]
    let precisionOptions = ["best", "tenMeters", "hundredMeters", "kilometer"]
    
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
                        .foregroundColor(.appCyan)
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
                    .foregroundColor(.appCyan)
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
                        
                        // Data Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data & Sync")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Server URL Setting
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "server.rack")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.appCyan)
                                            .frame(width: 24)

                                        Text("Server URL")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        if editingServerURL {
                                            Button("Cancel") {
                                                editingServerURL = false
                                                tempServerURL = ""
                                            }
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))

                                            Button("Save") {
                                                if !tempServerURL.isEmpty {
                                                    appSettings.serverURL = tempServerURL
                                                }
                                                editingServerURL = false
                                                tempServerURL = ""
                                            }
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.appCyan)
                                        } else {
                                            Button("Edit") {
                                                tempServerURL = appSettings.serverURL
                                                editingServerURL = true
                                            }
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.appCyan)
                                        }
                                    }

                                    if editingServerURL {
                                        TextField("Server URL", text: $tempServerURL)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(8)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                            .keyboardType(.URL)
                                    } else {
                                        Text(appSettings.serverURL)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.white.opacity(0.5))
                                            .lineLimit(2)
                                    }
                                }
                                .padding(16)

                                Divider()
                                    .overlay(Color.white.opacity(0.1))

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

                        // Sync Settings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sync Settings")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Location Poll Interval
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.appCyan)
                                            .frame(width: 24)

                                        Text("Location Poll Interval")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Text("\(locationPollInterval) min")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.5))
                                    }

                                    Picker("", selection: $locationPollInterval) {
                                        ForEach(locationIntervalOptions, id: \.self) { value in
                                            Text("\(value) min").tag(value)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: locationPollInterval) { _ in
                                        updateSyncSettings()
                                    }
                                }
                                .padding(16)

                                Divider()
                                    .overlay(Color.white.opacity(0.1))

                                // HealthKit Sync Interval
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.appCyan)
                                            .frame(width: 24)

                                        Text("HealthKit Sync Interval")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Text("\(healthkitSyncInterval) hr")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.5))
                                    }

                                    Picker("", selection: $healthkitSyncInterval) {
                                        ForEach(healthIntervalOptions, id: \.self) { value in
                                            Text("\(value) hr").tag(value)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: healthkitSyncInterval) { _ in
                                        updateSyncSettings()
                                    }
                                }
                                .padding(16)

                                Divider()
                                    .overlay(Color.white.opacity(0.1))

                                // Sync on App Open Toggle
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.appCyan)
                                        .frame(width: 24)

                                    Text("Sync on App Open")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Toggle("", isOn: $syncOnAppOpen)
                                        .labelsHidden()
                                        .onChange(of: syncOnAppOpen) { _ in
                                            updateSyncSettings()
                                        }
                                }
                                .padding(16)

                                Divider()
                                    .overlay(Color.white.opacity(0.1))

                                // Notifications Enabled Toggle
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.appCyan)
                                        .frame(width: 24)

                                    Text("Notifications Enabled")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Toggle("", isOn: $notificationsEnabled)
                                        .labelsHidden()
                                        .onChange(of: notificationsEnabled) { _ in
                                            updateSyncSettings()
                                        }
                                }
                                .padding(16)

                                Divider()
                                    .overlay(Color.white.opacity(0.1))

                                // Location Precision
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "scope")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.appCyan)
                                            .frame(width: 24)

                                        Text("Location Precision")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Text(locationPrecision)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.5))
                                    }

                                    Picker("", selection: $locationPrecision) {
                                        ForEach(precisionOptions, id: \.self) { value in
                                            Text(value.capitalized).tag(value)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: locationPrecision) { _ in
                                        updateSyncSettings()
                                    }
                                }
                                .padding(16)
                            }
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }

                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSyncSettings()
        }
        .alert(isPresented: $showLogoutConfirm) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .cancel(),
                secondaryButton: .destructive(Text("Log Out")) {
                    authManager.logout()
                }
            )
        }
    }

    private func loadSyncSettings() {
        let settings = appSettings.syncSettings
        locationPollInterval = settings.locationPollIntervalMinutes
        healthkitSyncInterval = settings.healthkitSyncIntervalHours
        syncOnAppOpen = settings.syncOnAppOpen
        notificationsEnabled = settings.notificationsEnabled
        locationPrecision = settings.locationPrecision
    }

    private func updateSyncSettings() {
        let newSettings = SyncSettings(
            locationPollIntervalMinutes: locationPollInterval,
            healthkitSyncIntervalHours: healthkitSyncInterval,
            syncOnAppOpen: syncOnAppOpen,
            notificationsEnabled: notificationsEnabled,
            locationPrecision: locationPrecision
        )
        appSettings.syncSettings = newSettings

        // Update the sync manager timer
        SyncManager.shared.updateSyncInterval()
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
                .foregroundColor(.appCyan)
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthenticationManager())
    }
}
