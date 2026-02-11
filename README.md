# HealthKit + Location Tracker iOS App

A production-ready iOS application built with SwiftUI that tracks Apple HealthKit data and GPS location, syncing data to a Node.js backend server every 30 minutes.

## 📱 Features

- **Modern SwiftUI UI** - iOS 15+ compatible with a beautiful dark gradient theme
- **HealthKit Integration** - Tracks:
  - Heart Rate & Resting Heart Rate
  - Heart Rate Variability (HRV)
  - Blood Pressure (Systolic/Diastolic)
  - Blood Oxygen (SpO2)
  - Steps & Distance
  - Active Energy & Calories
  - Flights Climbed
  - Sleep Analysis
  - Workout Data

- **Location Tracking** - GPS tracking with accuracy info
- **Background Sync** - Automatic sync every 30 minutes
- **Offline Support** - Queue data when offline, sync when connected
- **Authentication** - Secure login/signup flow
- **Beautiful Dashboard** - Real-time health stats display
- **Permission Management** - Easy-to-use permission request UI

## 🛠️ Tech Stack

- **Language**: Swift 5.5+
- **UI Framework**: SwiftUI (iOS 15+)
- **Data Persistence**: UserDefaults, Keychain, FileManager
- **Location**: CoreLocation
- **Health Data**: HealthKit Framework
- **Background Tasks**: BackgroundTasks
- **Networking**: URLSession

## 📋 Requirements

- Xcode 14.0+
- iOS 15.0+ deployment target
- Apple Developer Account (for testing HealthKit)
- Swift 5.5 or later

## 🚀 Setup Instructions

### 1. Clone the Project

```bash
git clone https://github.com/jonathanrmarsh4/HealthKit-LocationTracker-iOS.git
cd HealthKit-LocationTracker-iOS
```

### 2. Open in Xcode

```bash
# Create a new iOS App project in Xcode
open -a Xcode
```

Or open directly:
```bash
open HealthKit-LocationTracker-iOS.xcodeproj
```

### 3. Project Structure Setup

Copy all Swift files into your Xcode project:

```
HealthKit-LocationTracker-iOS/
├── HealthKitApp.swift (Main app entry point)
├── Models.swift (Data models)
├── Info.plist (Permissions configuration)
├── Managers/
│   ├── AuthenticationManager.swift
│   ├── HealthKitManager.swift
│   ├── LocationManager.swift
│   └── SyncManager.swift
└── Views/
    ├── LoginView.swift
    ├── DashboardView.swift
    ├── SettingsView.swift
    └── PermissionsView.swift
```

### 4. Configure Your Project

#### In Xcode:

1. **Create a new iOS App project:**
   - Product Name: `HealthKitTracker`
   - Organization Identifier: `com.healthkit.tracker` (or your own)
   - Team: Select your Apple Developer account

2. **Add files to project:**
   - Drag and drop all Swift files into Xcode
   - Ensure "Copy items if needed" is checked
   - Add to target

3. **Configure Signing & Capabilities:**
   - Select project in Xcode
   - Select target
   - Go to "Signing & Capabilities"
   - Add required capabilities:
     - ✅ HealthKit
     - ✅ Location Services (Always & When In Use)
     - ✅ Background Modes (Location Updates, Processing)

4. **Update Info.plist:**
   - Copy the `Info.plist` file provided in this repo
   - Replace the default one in Xcode

5. **Build Settings:**
   - iOS Deployment Target: 15.0 or later
   - Swift Language Dialect: Swift 5.5+

### 5. Configure Backend URL

Edit `SyncManager.swift` and update the server URL if needed:

```swift
private let serverURL = "https://nodeserver-production-8388.up.railway.app/location"
```

### 6. Build & Run

```bash
# Select simulator or device in Xcode
# Press Cmd+R to build and run
```

## 🔐 Permissions Required

The app requests the following permissions on first launch:

### Location
- **NSLocationAlwaysAndWhenInUseUsageDescription**: For continuous GPS tracking
- Required for background sync and location history

### HealthKit
- **NSHealthShareUsageDescription**: To read health data
- Includes: Steps, Heart Rate, Sleep, Workouts, Blood Pressure, SpO2, HRV

### Background Modes
- Location Updates: Tracks location in background
- Processing: Performs sync operations periodically

## 📤 API Integration

### Data Sync Format

The app sends data to your backend in this format:

```json
{
  "userId": "user-uuid",
  "timestamp": "2024-01-15T10:30:00Z",
  "health": {
    "timestamp": "2024-01-15T10:30:00Z",
    "steps": 8432,
    "heartRate": 72,
    "restingHeartRate": 58,
    "heartRateVariability": 45.2,
    "bloodPressureSystolic": 120,
    "bloodPressureDiastolic": 80,
    "bloodOxygen": 98.5,
    "activeEnergy": 245.3,
    "distance": 5.2,
    "flightsClimbed": 12,
    "sleepDuration": 28800,
    "workoutDuration": null,
    "workoutType": null,
    "workoutCalories": null
  },
  "location": {
    "timestamp": "2024-01-15T10:30:00Z",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "accuracy": 5.0,
    "altitude": 50.5,
    "speed": 1.2
  },
  "deviceInfo": {
    "deviceModel": "iPhone14,5",
    "osVersion": "17.0",
    "appVersion": "1.0",
    "isSimulator": false
  }
}
```

### Sync Schedule
- Automatic sync: Every 30 minutes
- Manual refresh: User can tap "Refresh Data" button
- Offline queuing: Failed syncs are queued and retried when online

## 🧪 Testing

### Test Credentials

Demo account available in login screen:
- Email: `demo@test.com`
- Password: `password123`

### Testing on Simulator

1. Simulate location in Xcode:
   - Debug → Simulate Location → Choose location
   
2. Simulate HealthKit data:
   - Use Health app to add sample data
   - App will read this data

3. Test offline mode:
   - Debug → Simulate Network Link Condition → Set to offline
   - Make changes, verify queue builds
   - Go back online and verify sync

## 📱 Device Testing

For full functionality, test on a real device:

1. Connect iPhone to Mac
2. Select device in Xcode
3. Run the app
4. Permissions will prompt automatically
5. HealthKit data will sync from Apple Health

## 🔔 Background Sync

The app uses two methods for background syncing:

1. **Timer-based** (30 minutes)
   - Runs while app is in foreground or suspended

2. **Background Processing Task**
   - Runs periodically in background
   - Requires Location Background Mode

## 🛡️ Security Features

- **Keychain Storage**: Login credentials encrypted in system keychain
- **Secure Transmission**: HTTPS to backend server
- **User ID Verification**: Each sync includes user ID
- **Timestamp Validation**: Server can validate data freshness

## 🐛 Troubleshooting

### HealthKit Not Working
- Make sure "HealthKit" capability is enabled in Xcode
- On simulator, populate Health app with sample data first
- Grant permissions when prompted
- Check Info.plist has NSHealthShareUsageDescription

### Location Not Updating
- Enable Location Services in Settings → Privacy → Location Services
- Grant "Always" or "While Using" permission
- On simulator, set a simulated location (Debug menu)

### Sync Failures
- Check network connection
- Verify backend URL in SyncManager.swift
- Check device clock is correct
- Review server logs for errors

### Permissions Not Showing
- Delete app and reinstall
- Go to Settings → Privacy and reset health permissions
- In iOS 17+, use Settings → Apps → [AppName] → Permissions

## 📊 Architecture

### MVVM Pattern
- **Models**: `Models.swift` - Data structures
- **ViewModels**: Manager classes (ObservableObject)
- **Views**: SwiftUI components

### Manager Classes
- `AuthenticationManager`: User login/signup
- `HealthKitManager`: HealthKit data fetching
- `LocationManager`: GPS tracking
- `SyncManager`: Backend synchronization

## 🚀 Deployment

### Before Production:

1. **Certificates & Identifiers**
   - Create App ID in Apple Developer
   - Configure capabilities
   - Create provisioning profile

2. **Code Signing**
   - Update bundle identifier
   - Select correct team

3. **TestFlight**
   - Archive in Xcode
   - Upload to TestFlight
   - Test on real devices

4. **App Store**
   - Update app description and screenshots
   - Set privacy policy URL
   - Submit for review

### Required Privacy Policy
You must include a privacy policy addressing:
- HealthKit data collection
- Location data usage
- Backend data storage
- User data retention

## 📝 Configuration

### Customization

**Change Sync Interval:**
```swift
// In SyncManager.swift
private let syncInterval: TimeInterval = 30 * 60 // Change 30 to your desired minutes
```

**Change Server URL:**
```swift
// In SyncManager.swift
private let serverURL = "https://your-api.com/location"
```

**Change Color Scheme:**
Edit color values in view files (e.g., LinearGradient colors)

## 📚 Dependencies

This project uses only native iOS frameworks:
- SwiftUI
- HealthKit
- CoreLocation
- UserNotifications
- Security (Keychain)
- BackgroundTasks

No external dependencies needed!

## 📄 License

This project is provided as-is for personal and commercial use.

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the code comments
3. Check Xcode console for error messages

## 📦 Package Contents

```
HealthKit-LocationTracker-iOS/
├── README.md (this file)
├── .gitignore
├── HealthKitApp.swift
├── Models.swift
├── Info.plist
├── Managers/
│   ├── AuthenticationManager.swift
│   ├── HealthKitManager.swift
│   ├── LocationManager.swift
│   └── SyncManager.swift
└── Views/
    ├── LoginView.swift
    ├── DashboardView.swift
    ├── SettingsView.swift
    └── PermissionsView.swift
```

## 🎯 Next Steps

1. Clone the repository
2. Open in Xcode
3. Configure signing & capabilities
4. Run on simulator or device
5. Test all permission flows
6. Customize for your needs
7. Deploy to App Store

---

Built with ❤️ for health tracking
