# HealthKit Location Tracker - iOS App

A production-ready iOS application that integrates HealthKit and CoreLocation to track health metrics and user location with secure server synchronization.

## ✅ Project Ready to Build

This is a **complete, ready-to-compile Xcode project**. All dependencies are configured.

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jonathanrmarsh4/HealthKit-LocationTracker-iOS.git
   cd HealthKit-LocationTracker-iOS
   ```

2. **Open in Xcode:**
   ```bash
   open HealthKitApp.xcodeproj
   ```
   Or simply double-click `HealthKitApp.xcodeproj`

3. **Build and Run:**
   - Press `Cmd + R` in Xcode, or
   - Select Product → Run from the menu

## 📋 Project Configuration

### Deployment Target
- **iOS:** 14.0 or later
- **Swift:** 5.0+
- **Xcode:** 13.2+

### Bundle Identifier
```
com.jonathansapps.HealthKitLocationTracker
```

### Frameworks & Capabilities

✅ **HealthKit Framework**
- Read/write health data
- Supports: Steps, Heart Rate, Sleep, Workouts, Blood Pressure, Blood Oxygen

✅ **CoreLocation Framework**
- Location permissions (Always + When In Use)
- Background location updates
- GPS position tracking

✅ **Required Permissions** (configured in Info.plist)
- `NSHealthShareUsageDescription` - Read health data
- `NSHealthUpdateUsageDescription` - Write health data
- `NSLocationAlwaysAndWhenInUseUsageDescription` - Always access location
- `NSLocationAlwaysUsageDescription` - Background location access
- `NSLocationWhenInUseUsageDescription` - Foreground location access

### Build Settings
- **Code Sign Style:** Automatic
- **Swift Version:** 5.0
- **Language:** Swift (SwiftUI)
- **Orientation:** Portrait (iPhone)

## 📁 Project Structure

```
HealthKitApp.xcodeproj/          # Xcode project configuration
├── project.pbxproj              # Project build settings

HealthKitApp.swift               # App entry point
AppDelegate.swift                # App lifecycle management

Views/                            # SwiftUI Views
├── DashboardView.swift           # Main dashboard interface
├── LoginView.swift               # Authentication screen
├── PermissionsView.swift         # Permission request flows
└── SettingsView.swift            # User settings

Managers/                         # Business logic & services
├── AuthenticationManager.swift    # User authentication
├── HealthKitManager.swift         # HealthKit data access
├── LocationManager.swift          # Location tracking
└── SyncManager.swift              # Server synchronization

Models.swift                       # Data models
NetworkManager.swift              # API communication
HealthKitManager.swift            # HealthKit integration (root level)
LocationManager.swift             # Location tracking (root level)
Info.plist                         # App configuration & permissions
```

## 🔧 Configuration for Your App

### 1. Set Your Development Team
In Xcode:
- Select `HealthKitApp` target
- Go to Signing & Capabilities tab
- Choose your Team in the dropdown

### 2. Update Bundle Identifier (Optional)
To use your own identifier:
- Select `HealthKitApp` target
- Build Settings tab
- Search "Bundle Identifier"
- Change `com.jonathansapps.HealthKitLocationTracker` to your identifier

### 3. Configure HealthKit Capabilities
Already configured! The project includes:
- HealthKit framework linked
- Required permissions in Info.plist

### 4. Configure Location Services
Already configured! The project includes:
- CoreLocation framework linked
- Background location modes enabled
- All required location permissions

## 🚀 Building & Running

### Simulator
```bash
# Run on default simulator
xcodebuild -scheme HealthKitApp -destination 'platform=iOS Simulator,name=iPhone 14'
```

### Device
1. Connect your iPhone via USB
2. Select your device in Xcode (top bar)
3. Press Cmd + R to build and run

### Archive for App Store
```bash
Product → Archive (or Cmd + Shift + K)
```

## 📝 Key Files Overview

### HealthKitApp.swift
Main app entry point. Sets up the app's root view and initializes managers.

### AppDelegate.swift
Handles app lifecycle events, background tasks, and notifications.

### HealthKitManager.swift
Manages all HealthKit operations:
- Requesting HealthKit access
- Reading health metrics
- Writing workout data
- Observing health data changes

### LocationManager.swift
Manages location tracking:
- Requesting location permissions
- Continuous background tracking
- Location updates with accuracy settings

### AuthenticationManager.swift
Handles user authentication and session management.

### SyncManager.swift
Synchronizes local health and location data with backend server.

### NetworkManager.swift
Manages API communication with secure HTTPS.

## 🔐 Privacy & Permissions

This app respects user privacy with proper permission flows:

- **First Launch:** Users grant HealthKit and Location permissions via native system dialogs
- **Transparent:** Clear explanations in Info.plist for why each permission is needed
- **Selective:** HealthKit access is limited to necessary health metrics
- **Revocable:** Users can revoke permissions anytime in Settings

## ❓ Troubleshooting

### "No Xcode project found"
Make sure you're in the correct directory with `HealthKitApp.xcodeproj`

### Build fails with framework errors
- Clean Build Folder (Cmd + Shift + K)
- Delete Derived Data: `~/Library/Developer/Xcode/DerivedData`
- Rebuild (Cmd + B)

### HealthKit permissions not appearing
- Ensure app has Health capability in Xcode
- Verify Info.plist has `NSHealthShareUsageDescription`
- Restart simulator and clear app data

### Location not updating
- Grant "Always" location permission, not just "While Using"
- Enable Background Modes → Location Updates
- Check Background App Refresh is enabled in iOS Settings

## 📞 Support

For issues or questions about this project, refer to:
- HealthKit documentation: https://developer.apple.com/documentation/healthkit
- CoreLocation documentation: https://developer.apple.com/documentation/corelocation
- SwiftUI documentation: https://developer.apple.com/documentation/swiftui

## 📄 License

This project is provided as-is for development and testing purposes.

---

**Ready to Build:** This project is fully configured and can be compiled immediately. Simply open in Xcode and press Cmd+R.
