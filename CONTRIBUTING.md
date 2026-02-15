# Contributing to HealthKit Location Tracker

Thank you for your interest in contributing! This document explains how to get involved.

## Getting Started

### Prerequisites
- Xcode 14+
- iOS 15+
- Apple Developer Account (for testing on device)
- Git

### Development Setup

```bash
# Clone the repo
git clone https://github.com/jonathanrmarsh4/HealthKit-LocationTracker-iOS.git
cd HealthKit-LocationTracker-iOS

# Open in Xcode
open HealthKitApp.xcodeproj

# Build and run
# Cmd+R to build and run on simulator or device
```

## Making Changes

### Code Style
- Follow Swift naming conventions (camelCase for functions/variables, PascalCase for types)
- Use meaningful variable names
- Comment complex logic
- Use `let` by default, `var` only when reassignment needed
- Add comprehensive error handling

### Project Structure
```
HealthKitApp.xcodeproj/
├── HealthKitApp.swift          # SwiftUI App entry point
├── Models.swift                # Data models
├── Views/                       # SwiftUI Views
│   ├── LoginView.swift
│   ├── DashboardView.swift
│   ├── SettingsView.swift
│   └── PermissionsView.swift
├── Managers/                    # Business logic
│   ├── AuthenticationManager.swift
│   ├── HealthKitManager.swift
│   ├── LocationManager.swift
│   ├── SyncManager.swift
│   └── NetworkManager.swift
├── Info.plist
├── README.md
└── DESIGN_SPEC.md
```

### Testing Your Changes

1. **Simulator Testing**
   ```bash
   # Run on iPhone simulator
   # Cmd+R in Xcode
   # Simulator → Features → Location → Select city/route
   ```

2. **Device Testing**
   ```bash
   # Build for physical device
   # Configure signing
   # Connect device, select in Xcode
   # Cmd+R to build and run
   ```

3. **HealthKit Data**
   - Use Health app to create sample data
   - App should read it automatically

4. **Location Simulation**
   - Simulator: Debug → Simulate Location
   - Device: Settings → Privacy → Location Services

### Commit Messages

Use clear, descriptive commit messages:
```
✅ Add blood pressure tracking to health metrics
🐛 Fix HealthKit authorization status check
📝 Update setup documentation
🔧 Improve location accuracy handling
🎨 Refactor NetworkManager error handling
```

## Pull Request Process

1. **Fork** the repository
2. **Create a branch** for your feature
   ```bash
   git checkout -b feature/add-xyz
   ```
3. **Make your changes** with clear commits
4. **Test thoroughly** on simulator and device
5. **Push to your fork**
   ```bash
   git push origin feature/add-xyz
   ```
6. **Open a Pull Request** with:
   - Clear title describing the change
   - Description of what it does
   - Why it's needed
   - Testing on which iOS versions
   - Screenshots if UI changes

### PR Checklist
- [ ] Code follows Swift style guidelines
- [ ] Tested on simulator (iOS 15+)
- [ ] Tested on physical device
- [ ] No print statements left
- [ ] Error handling is robust
- [ ] Documentation is updated
- [ ] No breaking changes

## Issues

### Reporting Bugs
Include:
- Description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- iOS version and device model
- Xcode version

### Feature Requests
Include:
- Use case / motivation
- How it would work
- Impact on existing features
- Design/UI considerations

## Areas for Contribution

- [ ] Add offline sync queue with persistence
- [ ] Add data export (CSV, PDF)
- [ ] Add charts/graphs for health trends
- [ ] Add workout detail tracking
- [ ] Add custom health metrics
- [ ] Add complications for Apple Watch
- [ ] Add Share Sheet for sharing data
- [ ] Add background notification support
- [ ] Add data privacy controls
- [ ] Add comprehensive unit tests
- [ ] Add UI tests
- [ ] Improve accessibility (VoiceOver)
- [ ] Add dark mode optimizations
- [ ] Add localization (multiple languages)

## SwiftUI Best Practices

- Use `@StateObject` for view models
- Use `@ObservedObject` for external state
- Avoid large view bodies (extract subviews)
- Use meaningful view names
- Keep state as close to leaves as possible
- Use protocols for dependency injection

## HealthKit Integration

- Always request permissions first
- Use `HKHealthStore()` as singleton
- Handle authorization changes gracefully
- Cache data appropriately
- Respect user privacy settings

## Networking Best Practices

- Always use HTTPS
- Handle network errors gracefully
- Implement retry logic
- Show loading states to user
- Cache responses when appropriate
- Time out long requests

## Testing Checklist

Before submitting PR, test:
- [ ] Login/signup flow
- [ ] Permission requests work
- [ ] Dashboard displays correctly
- [ ] Health data loads
- [ ] Location updates
- [ ] Sync succeeds
- [ ] Settings save/load
- [ ] Logout clears data
- [ ] Works on iOS 15
- [ ] Works on iOS 16
- [ ] Works on iOS 17
- [ ] Works on iPhone simulator
- [ ] Works on physical device

## Questions?

Feel free to:
- Open an issue for discussion
- Ask in PR comments
- Check existing issues for similar questions

## Code of Conduct

- Be respectful and inclusive
- No harassment or discrimination
- Constructive feedback only
- Report issues privately if needed

---

**Thank you for contributing!** 🚀
