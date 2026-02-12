import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutConfirm = false
    
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
                        .foregroundColor(.cyan)
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
                    .foregroundColor(.cyan)
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
                .foregroundColor(.cyan)
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
}
