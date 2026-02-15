# iOS HealthKit Tracker - Design & Integration Specification

## 📐 UI/UX Design Specification

### **Design System**

#### Color Palette
```
Primary: #00D9FF (Cyan)
Secondary: #1F2937 (Dark Gray)
Background: #0F172A (Deep Blue)
Surface: #1E293B (Card Background)
Success: #10B981 (Green)
Warning: #F59E0B (Amber)
Error: #EF4444 (Red)
Text Primary: #F1F5F9 (White)
Text Secondary: #94A3B8 (Gray)
```

#### Typography
```
Heading 1: 32pt, Bold (Montserrat or system)
Heading 2: 24pt, Semibold
Heading 3: 18pt, Semibold
Body: 16pt, Regular
Small: 14pt, Regular
Caption: 12pt, Regular
```

---

## 📱 App Screens & Layouts

### **1. Login Screen**
**Purpose**: User authentication and onboarding

**Layout:**
```
┌─────────────────────────┐
│    Logo/App Name        │  (Top: 20% of screen)
├─────────────────────────┤
│  Email TextField        │  (Primary accent border)
│  ••••••••••••••••       │  (Password masked)
├─────────────────────────┤
│  [Login Button]         │  (Full width, cyan bg)
│  Don't have account?    │
│  [Sign Up Link]         │
├─────────────────────────┤
│  Demo Credentials:      │  (Optional: for testing)
│  email: demo@app.com    │
│  pass: Demo123!         │
└─────────────────────────┘
```

**Components:**
- TextField (email, password, secureText)
- Button (Login, Sign Up)
- ActivityIndicator (while authenticating)
- ErrorAlert (invalid credentials)

**Behavior:**
- Validate email format before submit
- Show loading spinner during auth
- Store token in Keychain on success
- Auto-login if token exists & valid

---

### **2. Permissions Screen**
**Purpose**: Request HealthKit & Location permissions

**Layout:**
```
┌─────────────────────────┐
│   📍 Location Access    │
│  "We need your GPS      │
│   location for..."      │
│  [REQUEST PERMISSION]   │  (Cyan, disabled if granted)
│  ✅ Status: Granted     │
├─────────────────────────┤
│   ❤️ HealthKit Access   │
│  "We need access to:    │
│   - Steps, Heart Rate   │
│   - Sleep, Workouts"    │
│  [REQUEST PERMISSION]   │
│  ⏳ Status: Pending     │
├─────────────────────────┤
│  [Continue] (disabled   │
│   until both granted)   │
└─────────────────────────┘
```

**Components:**
- PermissionCard (icon, title, description, button)
- StatusBadge (Granted/Pending/Denied)
- Button (disabled until all granted)

**Behavior:**
- Display current permission status
- Show native iOS permission dialogs
- Update UI when permissions change
- Prevent navigation until both granted

---

### **3. Dashboard Screen**
**Purpose**: Display current health metrics & location status

**Layout:**
```
┌─────────────────────────┐
│  👋 Welcome, [Name]!    │  (Header: 10%)
│  Last sync: 2 min ago   │
├─────────────────────────┤
│ 📍 Location: Perth, WA  │  (Location card)
│ Lat: -31.95°            │
│ Lon: 115.86°            │
│ Accuracy: 5000m         │
│ [📍 Map] [🔄 Refresh]  │
├─────────────────────────┤
│ HEALTH METRICS          │  (Scrollable grid)
├─────────────────────────┤
│ 👣 Steps                │
│ 8,234                   │  (Large number)
│ 📈 Goal: 10,000         │  (Progress bar: 82%)
├─────────────────────────┤
│ ❤️ Heart Rate           │
│ 72 bpm (Resting: 58)    │
│ 📈 HRV: 45 ms           │
├─────────────────────────┤
│ 😴 Sleep                │
│ 7h 32m (Last night)     │
│ 📈 Quality: Good        │
├─────────────────────────┤
│ 🩸 Blood Pressure       │
│ 120/80 mmHg             │
│ Status: ✅ Normal       │
├─────────────────────────┤
│ 💨 Blood Oxygen         │
│ 98%                     │
│ Status: ✅ Good         │
├─────────────────────────┤
│ 🔥 Active Energy        │
│ 450 kcal                │
│ 📈 Goal: 500 kcal       │
├─────────────────────────┤
│ 🏃 Workouts             │
│ 2 workouts (today)      │
│ • Running: 45 min       │
│ • Cycling: 30 min       │
├─────────────────────────┤
│ 📡 Sync Status          │  (Bottom: persistent)
│ ✅ Synced 2 min ago     │
│ [🔄 Sync Now]           │
│ Next auto-sync: 28 min  │
├─────────────────────────┤
│ ⚙️ Settings  👤 Profile │  (Tab bar)
└─────────────────────────┘
```

**Components:**
- HeaderCard (greeting, last sync time)
- LocationCard (coordinates, accuracy, map/refresh buttons)
- MetricCard (icon, title, value, status, progress bar)
- SyncStatusBar (status, last sync, next sync, refresh button)
- TabBar (Dashboard, Settings, Profile)

**Behavior:**
- Refresh metrics when screen appears
- Show loading state while fetching
- Update sync timer countdown
- Tap metric card to see details/history
- Manual refresh button triggers immediate sync

---

### **4. Settings Screen**
**Purpose**: App configuration & user management

**Layout:**
```
┌─────────────────────────┐
│  ⚙️ Settings            │
├─────────────────────────┤
│  SYNC SETTINGS          │
│  Auto-sync Every 30 min │  (Toggle)
│  Sync on Wi-Fi Only     │  (Toggle)
│  Show Notifications     │  (Toggle)
├─────────────────────────┤
│  PRIVACY                │
│  Share Health Data      │  (Toggle)
│  Location Precision     │  (Dropdown: High/Medium/Low)
│  Clear Local Cache      │  (Button)
├─────────────────────────┤
│  ACCOUNT                │
│  Logged in as:          │
│  jonathan@example.com   │
│  [Change Password]      │
│  [Logout]               │
│  [Delete Account]       │
├─────────────────────────┤
│  ABOUT                  │
│  App Version: 1.0.0     │
│  Build: 123             │
│  Server: Railway        │
│  [Contact Support]      │
└─────────────────────────┘
```

---

## 🔌 API Endpoints & Integration

### **Base URL**
```
https://nodeserver-production-8388.up.railway.app
```

---

### **1. Authentication Endpoints**

#### **POST /auth/login**
Login user

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user123",
      "email": "user@example.com",
      "name": "Jonathan Marsh"
    }
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "error": "Invalid email or password"
}
```

**Implementation:**
```swift
// Store token in Keychain
KeychainManager.save(token: response.data.token)

// Use token in all future requests
var headers: [String: String] = [
  "Authorization": "Bearer \(token)",
  "Content-Type": "application/json"
]
```

---

#### **POST /auth/signup**
Register new user

**Request:**
```json
{
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "name": "John Doe"
}
```

**Response (201 Created):**
```json
{
  "status": "ok",
  "data": {
    "token": "...",
    "user": { ... }
  }
}
```

---

### **2. Location & Health Data Endpoints**

#### **POST /location**
Send location + health data (called every 30 min)

**Request:**
```json
{
  "latitude": -31.9522,
  "longitude": 115.8614,
  "timestamp": "2026-02-11T19:51:00Z",
  "device": "iPhone",
  "health": {
    "steps": 8234,
    "heart_rate": 72,
    "resting_heart_rate": 58,
    "hrv": 45,
    "blood_pressure_systolic": 120,
    "blood_pressure_diastolic": 80,
    "blood_oxygen": 98,
    "active_energy": 450,
    "distance": 5.2,
    "flights_climbed": 12,
    "sleep": {
      "total_minutes": 450,
      "samples_count": 1
    },
    "workouts": [
      {
        "type": "running",
        "duration_minutes": 45,
        "calories": 380,
        "distance": 5.2
      }
    ]
  }
}
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "message": "Location and health data received",
  "data": {
    "latitude": -31.9522,
    "longitude": 115.8614,
    "timestamp": "2026-02-11T19:51:00Z"
  }
}
```

**Error Response (400):**
```json
{
  "error": "Missing required fields: latitude and longitude"
}
```

---

#### **GET /location**
Retrieve latest location + health data

**Request:**
```
GET /location
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "data": {
    "latitude": -31.9522,
    "longitude": 115.8614,
    "timestamp": "2026-02-11T19:51:00Z",
    "device": "iPhone",
    "health": { ... }
  }
}
```

---

#### **GET /location/history?days=7**
Get location history (last 7 days)

**Response:**
```json
{
  "status": "ok",
  "data": [
    { "latitude": -31.9522, "longitude": 115.8614, "timestamp": "2026-02-11T19:51:00Z" },
    { "latitude": -31.9520, "longitude": 115.8610, "timestamp": "2026-02-11T19:21:00Z" }
  ]
}
```

---

### **3. User Profile Endpoints**

#### **GET /user/profile**
Get user profile

**Response:**
```json
{
  "status": "ok",
  "data": {
    "id": "user123",
    "email": "jonathan@example.com",
    "name": "Jonathan Marsh",
    "created_at": "2026-02-01T10:00:00Z"
  }
}
```

---

#### **PUT /user/profile**
Update user profile

**Request:**
```json
{
  "name": "Jonathan M.",
  "password": "NewPassword123!"
}
```

---

#### **DELETE /user/account**
Delete account (requires password confirmation)

**Request:**
```json
{
  "password": "CurrentPassword123!"
}
```

---

### **4. Health Data Endpoints**

#### **GET /health/stats?date=2026-02-11**
Get daily health stats

**Response:**
```json
{
  "status": "ok",
  "data": {
    "date": "2026-02-11",
    "steps": 8234,
    "active_energy": 450,
    "sleep": 450,
    "workouts": 2
  }
}
```

---

## 🔄 Data Sync Architecture

### **Sync Flow (Every 30 minutes)**

```
App Background → HealthKitManager.fetchTodayData()
    ↓
LocationManager.getCurrentLocation()
    ↓
Combine data into payload
    ↓
NetworkManager.POST /location {payload}
    ↓
Server stores data
    ↓
App updates local UI
    ↓
If failed: Queue for retry in 5 min
    ↓
Sleep until next 30-min cycle
```

---

### **Error Handling**

**Network Errors:**
```swift
do {
  let response = try await networkManager.sendData(payload)
} catch NetworkError.noConnection {
  // Queue for offline sync
  offlineQueue.append(payload)
} catch NetworkError.timeout {
  // Retry in 5 minutes
  retryTimer = Timer.scheduledTimer(withTimeInterval: 300)
} catch NetworkError.serverError(let code) {
  // Log error, notify user if critical
  ErrorNotificationService.show("Sync failed: \(code)")
}
```

---

## 📊 Data Models

### **Location**
```swift
struct LocationData {
  let latitude: Double      // Required
  let longitude: Double     // Required
  let accuracy: Double?     // Optional: meters
  let altitude: Double?     // Optional: meters
  let speed: Double?        // Optional: m/s
  let timestamp: String     // ISO8601 format
  let device: String        // "iPhone"
}
```

### **HealthData**
```swift
struct HealthData {
  let steps: Int?
  let heartRate: Int?
  let restingHeartRate: Int?
  let hrv: Double?          // ms
  let bloodPressureSystolic: Int?
  let bloodPressureDiastolic: Int?
  let bloodOxygen: Int?     // %
  let activeEnergy: Double? // kcal
  let distance: Double?     // km
  let flightsClimbed: Int?
  let sleep: SleepData?
  let workouts: [WorkoutData]?
}
```

---

## ✅ Testing Checklist

- [ ] Login works with demo credentials
- [ ] Permission request flows work
- [ ] Dashboard loads and displays metrics
- [ ] Manual sync button sends data to server
- [ ] Auto-sync triggers every 30 minutes
- [ ] Offline queue retries when connection restored
- [ ] Settings screen saves preferences
- [ ] Logout clears tokens and user data
- [ ] Error messages display appropriately
- [ ] Loading states show during network requests

---

## 🚀 Deployment Checklist

- [ ] Update bundle identifier (com.yourname.healthkit-tracker)
- [ ] Configure signing team
- [ ] Add HealthKit capability
- [ ] Add Location capability
- [ ] Test on real device
- [ ] Verify permissions work
- [ ] Check background sync in real conditions
- [ ] Build for distribution (AppStore/TestFlight)
