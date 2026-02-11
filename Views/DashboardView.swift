import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var syncManager: SyncManager
    
    @State private var showSettings = false
    @State private var showPermissionsAlert = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hello, \(authManager.currentUser?.email.split(separator: "@").first ?? "User")!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Today's Health Overview")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gear")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.appCyan)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Status Cards
                        StatusCardsView()
                        
                        // Health Stats Grid
                        HealthStatsGridView()
                        
                        // Location Status Card
                        LocationStatusCard()
                        
                        // Sync Status Card
                        SyncStatusCard()
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await healthManager.fetchHealthData()
                                    await syncManager.performManualSync()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh Data")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(14)
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
                                .cornerRadius(12)
                            }
                            
                            NavigationLink(destination: PermissionsView()) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Permissions Status")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Request permissions on first load
                if !healthManager.isAuthorized {
                    Task {
                        await healthManager.requestHealthKitAuthorization()
                    }
                }
                
                if locationManager.locationStatus == .unknown {
                    locationManager.requestLocationPermission()
                }
                
                // Initial data fetch
                Task {
                    await healthManager.fetchHealthData()
                }
            }
        }
    }
}

// MARK: - Status Cards

struct StatusCardsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Heart Rate Card
            StatCard(
                icon: "heart.fill",
                title: "Heart Rate",
                value: healthManager.healthData.heartRate.map(String.init) ?? "--",
                unit: "bpm",
                color: Color(red: 1.0, green: 0.2, blue: 0.3)
            )
            
            // Steps Card
            StatCard(
                icon: "figure.walk",
                title: "Steps",
                value: healthManager.healthData.steps.map(String.init) ?? "--",
                unit: "steps",
                color: Color(red: 0.2, green: 0.8, blue: 0.6)
            )
            
            // Blood Oxygen Card
            StatCard(
                icon: "lungs.fill",
                title: "O₂",
                value: healthManager.healthData.bloodOxygen.map { String(format: "%.0f", $0) } ?? "--",
                unit: "%",
                color: Color(red: 0.3, green: 0.6, blue: 1.0)
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Health Stats Grid

struct HealthStatsGridView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Metrics")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 12) {
                DetailStatCard(
                    icon: "heart",
                    title: "Resting HR",
                    value: healthManager.healthData.restingHeartRate.map(String.init) ?? "--",
                    unit: "bpm"
                )
                
                DetailStatCard(
                    icon: "waveform.circle.fill",
                    title: "HRV",
                    value: healthManager.healthData.heartRateVariability.map { String(format: "%.0f", $0) } ?? "--",
                    unit: "ms"
                )
                
                DetailStatCard(
                    icon: "flame.fill",
                    title: "Energy",
                    value: healthManager.healthData.activeEnergy.map { String(format: "%.0f", $0) } ?? "--",
                    unit: "kcal"
                )
                
                DetailStatCard(
                    icon: "location.fill",
                    title: "Distance",
                    value: healthManager.healthData.distance.map { String(format: "%.2f", $0) } ?? "--",
                    unit: "km"
                )
                
                DetailStatCard(
                    icon: "arrow.up.right.and.arrow.down.left",
                    title: "Flights",
                    value: healthManager.healthData.flightsClimbed.map(String.init) ?? "--",
                    unit: "flights"
                )
                
                DetailStatCard(
                    icon: "bed.double.fill",
                    title: "Sleep",
                    value: healthManager.healthData.sleepDuration.map { String(format: "%.1f", $0 / 3600) } ?? "--",
                    unit: "hours"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct DetailStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appCyan)
                
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appCyan.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Location Status Card

struct LocationStatusCard: View {
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        
                        Text("Location Tracking")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(locationManager.locationStatus.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let location = locationManager.currentLocation {
                        Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                            .monospaced()
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(
                        locationManager.locationStatus == .enabled ? Color.green : Color.red.opacity(0.3)
                    )
                    .frame(width: 12, height: 12)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sync Status Card

struct SyncStatusCard: View {
    @EnvironmentObject var syncManager: SyncManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .foregroundColor(.appCyan)
                        
                        Text("Sync Status")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(syncManager.syncStatus.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if !syncManager.offlineQueue.isEmpty {
                        Text("📦 \(syncManager.offlineQueue.count) items in queue")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                }
                
                Spacer()
                
                if case .syncing = syncManager.syncStatus {
                    ProgressView()
                        .tint(.appCyan)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AuthenticationManager())
            .environmentObject(HealthKitManager.shared)
            .environmentObject(LocationManager.shared)
            .environmentObject(SyncManager.shared)
    }
}
