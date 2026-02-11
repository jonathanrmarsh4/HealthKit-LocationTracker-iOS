# HealthKit + Location Tracker iOS App

A native iOS app that tracks your health data (steps, heart rate, sleep, workouts, etc.) and GPS location, sending updates to a Node.js backend every 30 minutes.

## Features

✅ **Location Tracking**
- Precise GPS coordinates
- Background location updates
- Always & When In Use authorization

✅ **HealthKit Integration**
- Steps
- Heart rate (current & resting)
- Heart rate variability (HRV)
- Blood pressure (systolic & diastolic)
- Blood oxygen
- Active & basal energy
- Distance walked/run
- Flights climbed
- Sleep analysis
- Workouts

✅ **Background Execution**
- Runs every 30 minutes in background
- Uses `BGTaskScheduler` for reliable scheduling
- Syncs when app comes to foreground

✅ **Secure Data Transmission**
- HTTPS only
- Sends location + health data to Node server
- Query parameters + JSON body support

## Setup Instructions

### 1. Create Xcode Project

```bash
# Create a new iOS app in Xcode
# File → New → Project → App
# Choose:
#   - Product Name: HealthKitTracker
#   - Team: Your Apple Developer Team
#   - Organization ID: com.yourname
#   - Interface: Storyboard
#   - Life Cycle: UIKit App Delegate
```

### 2. Copy Swift Files

Copy these files into your Xcode project:
- `AppDelegate.swift`
- `HealthKitManager.swift`
- `LocationManager.swift`
- `NetworkManager.swift`

Replace the existing `AppDelegate.swift` with the one provided.

### 3. Update Info.plist

Replace your app's `Info.plist` with the provided `Info.plist` that includes all required privacy strings and background modes.

### 4. Enable Required Capabilities

In Xcode:
1. Select your project → Target
2. Go to "Signing & Capabilities"
3. Click "+ Capability" and add:
   - **HealthKit** (enable all permissions)
   - **Background Modes** → Enable:
     - Location Updates
     - Background Fetch
     - Background Processing

### 5. Configure App Groups (Optional, for shared data)

1. "+ Capability" → App Groups
2. Add group identifier: `group.com.yourname.healthkit-tracker`

### 6. Update Server URL

In `AppDelegate.swift`, update the server URL:
```swift
networkManager = NetworkManager(serverURL: "https://nodeserver-production-8388.up.railway.app")
```

### 7. Build & Run

```bash
# Build for iPhone
# Product → Build (Cmd+B)
# Product → Run (Cmd+R)
```

## Data Sent to Server

Every 30 minutes, the app sends:

```json
{
  "latitude": -31.95,
  "longitude": 115.86,
  "timestamp": "2026-02-11T19:00:00Z",
  "device": "iPhone",
  "health": {
    "steps": 8234,
    "heart_rate": 72,
    "resting_heart_rate": 60,
    "hrv": 45,
    "blood_pressure_systolic": 120,
    "blood_pressure_diastolic": 80,
    "blood_oxygen": 98,
    "active_energy": 450,
    "distance": 5.2,
    "flights_climbed": 12,
    "sleep": {
      "total_minutes": 480,
      "samples_count": 2
    },
    "workouts": [
      {
        "type": 1,
        "duration_minutes": 45,
        "calories": 380,
        "distance": 5.2
      }
    ],
    "timestamp": "2026-02-11T19:00:00Z"
  }
}
```

## Permissions Required

When you first run the app, it will request:

1. **Location Access**
   - "Always & When In Use" → tap "Always Allow"

2. **HealthKit Access**
   - Tap "Allow" for each health data category

## Testing

### Verify Data Is Being Sent

Check the Node server at:
```
https://nodeserver-production-8388.up.railway.app/location
```

Should show your latest location + health data.

### Simulate Location in Xcode

1. Run app in Simulator
2. Debug → Location → Select a location

### Test Background Execution

1. Run the app
2. Click home button to send app to background
3. Wait 30 seconds (or trigger manually in Debug menu)
4. Check server for updated data

## Troubleshooting

### "HealthKit authorization failed"
- Go to Settings → Health → Data Access & Devices
- Make sure the app has access

### "Location authorization denied"
- Go to Settings → Privacy → Location Services
- Enable for this app

### Data not sending
- Check network connection (WiFi or cellular)
- Verify server URL is correct
- Check server logs for errors

### Background task not running
- Ensure app is not force-closed
- Check Settings → General → Background App Refresh is enabled

## Project Structure

```
HealthKit-LocationTracker-iOS/
├── AppDelegate.swift              # App lifecycle & task scheduling
├── HealthKitManager.swift         # HealthKit data fetching
├── LocationManager.swift          # GPS location tracking
├── NetworkManager.swift           # Server communication
├── Info.plist                     # App configuration & permissions
└── README.md                      # This file
```

## Node Server Integration

The app sends data to your Node server which stores it for querying. The server should have:

- `GET /location?latitude=X&longitude=Y&timestamp=T&device=iPhone` endpoint
- `POST /location` endpoint with JSON body
- Ability to store and retrieve latest location + health data

See `../Node_Server` for server code.

## Security Notes

- ✅ Uses HTTPS only
- ✅ Location data is private (no storage on server beyond latest)
- ✅ HealthKit data is encrypted in transit
- ✅ No personal data is logged
- ✅ App requires "Always" location auth for background tracking

## Future Improvements

- [ ] Local caching of health data
- [ ] Offline sync queue
- [ ] Custom health data types
- [ ] Workout detail tracking
- [ ] Voice notifications
- [ ] Widget showing latest data

## License

MIT

## Support

For issues or questions, check:
1. Console logs in Xcode
2. Device Settings → Privacy for permission status
3. Node server logs for network errors
