# Step-by-Step Setup Guide

Complete guide to create and run the HealthKit Location Tracker iOS app from scratch.

## Prerequisites

- Mac with Xcode 14.0+ installed
- iOS device or simulator (iOS 15+)
- Apple Developer Account (for HealthKit on real device)
- Git installed

## Step 1: Create New Xcode Project

1. Open Xcode
2. Click "Create a new Xcode project"
3. Select "iOS"
4. Select "App" template
5. Click "Next"

Configure project:
- **Product Name**: `HealthKitTracker`
- **Team**: Select your Apple team
- **Organization Identifier**: `com.healthkit.tracker`
- **Bundle Identifier**: `com.healthkit.tracker` (auto-filled)
- **Interface**: SwiftUI
- **Life Cycle**: SwiftUI App
- **Language**: Swift
- **Storage**: None
- **Include Tests**: Unchecked

Click "Next" and save to desired location.

## Step 2: Add Swift Source Files

1. In Xcode, right-click project in left panel
2. Select "Add Files to..."
3. Select all Swift files from this repository:
   - HealthKitApp.swift
   - Models.swift
   - All files in Managers/ folder
   - All files in Views/ folder

4. In dialog:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to target "HealthKitTracker"

5. Click "Add"

## Step 3: Delete Default Files

1. In Xcode, select these auto-generated files:
   - ContentView.swift
   - HealthKitTrackerApp.swift (the default one)

2. Delete them (⌘Delete) and choose "Remove Reference"

## Step 4: Update Info.plist

1. Right-click on Info.plist
2. Select "Open As" → "Source Code"
3. Replace entire content with the Info.plist from this repo
4. Save (⌘S)

## Step 5: Configure Signing & Capabilities

1. Select project in left panel
2. Select "HealthKitTracker" target
3. Go to "Signing & Capabilities" tab

Add capabilities by clicking "+ Capability":

### Required Capabilities:

1. **HealthKit**
   - Click "+ Capability"
   - Search and select "HealthKit"
   - Click "Add"

2. **Background Modes**
   - Click "+ Capability"
   - Search and select "Background Modes"
   - Check:
     - ✅ Location updates
     - ✅ Background processing

3. **Push Notifications** (optional, for sync notifications)
   - Click "+ Capability"
   - Search and select "Push Notifications"

4. **Home Kit** (if using HomeKit devices)
   - Skip unless needed

### Verify Entitlements:
- You should see new "HealthKitTracker.entitlements" file
- It should contain:
  ```xml
  <key>com.apple.developer.healthkit</key>
  <true/>
  ```

## Step 6: Build Settings

1. Go to "Build Settings" tab
2. Search for "iOS Deployment Target"
3. Set to **15.0** or higher
4. Search for "Swift Language Dialect"
5. Set to **Swift 5.5** or later

## Step 7: Configure Team & Signing

1. Go to "Signing & Capabilities"
2. Under "Signing":
   - **Team**: Select your Apple team
   - **Bundle Identifier**: `com.healthkit.tracker` (or your own)
   - **Signing Certificate**: Automatically selected
   - **Provisioning Profile**: Automatically created

## Step 8: Create Launch Screen (Optional)

1. File → New → File
2. Select "SwiftUI View"
3. Name it "LaunchScreen"
4. Add:

```swift
import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.15, green: 0.2, blue: 0.35)
                ]),
                startPoint: .topLeadingPoint,
                endPoint: .bottomTrailingPoint
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                
                Text("Health Tracker")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}
```

## Step 9: Test Build

1. Select a simulator (e.g., "iPhone 15")
2. Press ⌘B to build
3. Fix any build errors:
   - Check Swift syntax
   - Verify all files are added to target
   - Check Info.plist is valid

## Step 10: Run on Simulator

1. Select iPhone simulator in top toolbar
2. Press ⌘R to run
3. App should launch with login screen

### First Launch Checklist:
- [ ] Login screen appears
- [ ] Can enter demo@test.com / password123
- [ ] Redirects to dashboard
- [ ] Health stat cards visible
- [ ] Status cards show data

## Step 11: Test Permissions (Simulator)

1. Go to Settings app → Privacy
2. Enable:
   - **Location Services** → Select "While Using" or "Always"
   - **Health** → Toggle on

3. Back in app, tap "Permissions Status"
4. Tap "Enable HealthKit Access"
5. Permissions should update

## Step 12: Simulate Health Data

1. In Xcode, run app on simulator
2. On Mac, open Health app (or use shortcut)
3. Add sample health data:
   - Steps
   - Heart rate
   - Sleep
   - Workouts

4. Return to app and tap "Refresh Data"
5. Data should appear in dashboard

## Step 13: Test Location (Simulator)

1. In Xcode while running:
   - Debug → Simulate Location
   - Choose a location (e.g., "San Francisco")

2. Location card should show coordinates
3. Distance/altitude should be updated

## Step 14: Test Offline Mode

1. Debug → Simulate Network Link Condition
2. Set to "Poor WiFi" or "Offline"
3. Tap "Refresh Data"
4. Check "Sync Status" card shows error
5. Note appears in offline queue

Back online:
1. Debug → Simulate Network Link Condition
2. Set to "Good WiFi"
3. Tap "Refresh Data"
4. Should sync successfully

## Step 15: Build for Real Device

### Setup Device:

1. Connect iPhone to Mac with USB
2. Xcode should detect device
3. Trust the device on iPhone

### Build for Device:

1. In Xcode top toolbar:
   - Product → Destination → Select your device

2. Press ⌘R to build and run

3. App will be installed and launched on device

### Test on Device:

- [ ] Location permission prompt appears
- [ ] HealthKit permission prompt appears
- [ ] Can grant permissions
- [ ] Real location data appears
- [ ] Real health data from Health app appears
- [ ] Manual refresh syncs successfully

## Step 16: Customize for Production

1. **Change Bundle Identifier**:
   - Project → Target → General
   - Update Bundle Identifier to your domain

2. **Update App Name**:
   - Project → Product Name
   - Or use Info.plist CFBundleDisplayName

3. **Update Server URL**:
   - Open SyncManager.swift
   - Update `serverURL` to your backend

4. **Update Colors/Branding**:
   - Edit gradient colors in views
   - Update app icon
   - Update launch screen

## Step 17: Archive for TestFlight

1. Select generic iOS device (not simulator)
2. Product → Archive
3. Wait for build to complete
4. Xcode Organizer opens
5. Select latest archive
6. Click "Distribute App"
7. Choose TestFlight
8. Follow prompts

## Troubleshooting

### Build Fails with Swift Errors
- Clean build: ⌘Shift+K
- Delete derived data: Xcode → Preferences → Locations → Derived Data
- Rebuild

### HealthKit Not Available
- Ensure HealthKit capability is added
- Check Info.plist has NSHealthShareUsageDescription
- Restart Xcode

### Location Not Working
- Check Info.plist has location descriptions
- Grant permission in Settings
- On simulator, use Debug → Simulate Location

### App Crashes on Launch
- Check console for error messages (⌘9)
- Verify all Swift files added to target
- Check Models.swift has all required types

### Permissions Not Showing
- Go to device Settings → General → Reset
- Select "Reset Location & Privacy"
- Delete app
- Reinstall from Xcode

## Next Steps

1. ✅ Get the app running
2. Test all features thoroughly
3. Customize branding/colors
4. Update backend URL
5. Create privacy policy
6. Submit to App Store

For detailed feature documentation, see README.md
