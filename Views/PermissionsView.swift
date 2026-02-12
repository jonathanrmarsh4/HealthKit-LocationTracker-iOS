import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.presentationMode) var presentationMode
    
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
                    
                    Text("Permissions")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("")
                    }
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                    .opacity(0)
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
                        // Location Permission
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Location Access")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                            
                            PermissionCard(
                                icon: "location.fill",
                                title: "Location Tracking",
                                description: "GPS tracking for your workouts and daily activities",
                                status: locationManager.locationStatus.description,
                                statusColor: locationStatusColor,
                                action: {
                                    locationManager.requestLocationPermission()
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        // HealthKit Permissions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Health Data Access")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 12) {
                                HealthKitPermissionItem(
                                    icon: "heart.fill",
                                    title: "Heart Rate",
                                    description: "Current and historical heart rate data",
                                    isAuthorized: healthManager.isAuthorized
                                )
                                
                                HealthKitPermissionItem(
                                    icon: "figure.walk",
                                    title: "Steps",
                                    description: "Daily step count and walking distance",
                                    isAuthorized: healthManager.isAuthorized
                                )
                                
                                HealthKitPermissionItem(
                                    icon: "waveform.circle.fill",
                                    title: "Heart Rate Variability",
                                    description: "HRV data for stress and recovery",
                                    isAuthorized: healthManager.isAuthorized
                                )
                                
                                HealthKitPermissionItem(
                                    icon: "lungs.fill",
                                    title: "Blood Oxygen",
                                    description: "SpO2 measurements",
                                    isAuthorized: healthManager.isAuthorized
                                )
                                
                                HealthKitPermissionItem(
                                    icon: "heart.text.square.fill",
                                    title: "Blood Pressure",
                                    description: "Systolic and diastolic readings",
                                    isAuthorized: healthManager.isAuthorized
                                )
                                
                                HealthKitPermissionItem(
                                    icon: "flame.fill",
                                    title: "Active Energy",
                                    description: "Calories burned from activity",
                                    isAuthorized: healthManager.isAuthorized
                                )
                                
                                HealthKitPermissionItem(
                                    icon: "bed.double.fill",
                                    title: "Sleep Analysis",
                                    description: "Sleep duration and quality",
                                    isAuthorized: healthManager.isAuthorized
                                )
                                
                                HealthKitPermissionItem(
                                    icon: "figure.stairs",
                                    title: "Workouts",
                                    description: "Exercise activities and metrics",
                                    isAuthorized: healthManager.isAuthorized
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Enable Button
                        if !healthManager.isAuthorized {
                            VStack(spacing: 12) {
                                Button {
                                    Task {
                                        await healthManager.requestHealthKitAuthorization()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                        Text("Enable HealthKit Access")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(14)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(red: 0, green: 0.8, blue: 1), .blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(16)
                        }
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Why We Need These Permissions")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("We collect health and location data to sync with your backend server every 30 minutes. Your privacy is important - all data is sent securely and never shared.")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(14)
                            .background(ColorColor(red: 0, green: 0.8, blue: 1).opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    var locationStatusColor: Color {
        switch locationManager.locationStatus {
        case .enabled:
            return .green
        case .denied:
            return .red
        case .requestingAlways:
            return .yellow
        default:
            return .gray
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    let statusColor: Color
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(statusColor)
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                }
            }
            
            Button(action: action) {
                Text("Manage Permission")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(ColorColor(red: 0, green: 0.8, blue: 1).opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

struct HealthKitPermissionItem: View {
    let icon: String
    let title: String
    let description: String
    let isAuthorized: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0, green: 0.8, blue: 1))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: isAuthorized ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isAuthorized ? .green : .gray.opacity(0.5))
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }
}

#Preview {
    PermissionsView()
        .environmentObject(HealthKitManager.shared)
        .environmentObject(LocationManager.shared)
}
