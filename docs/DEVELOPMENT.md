# Growatt Control App - Development Documentation

## Project Goal

A simple Android app (Flutter) that allows you to:
- View the status of your Growatt inverters
- Turn inverters on and off
- No server needed - app connects directly to Growatt API

## Technology Stack

- **Framework**: Flutter (Dart)
- **Platform**: Android (iOS possible in future)
- **API**: Growatt OpenAPI v4
- **State Management**: Provider
- **HTTP Client**: http package
- **Local Storage**: shared_preferences

## Architecture

```
Flutter App (on smartphone)
  ↓ HTTPS
Growatt API Servers
  ↓
Inverter data
```

**No custom server/backend needed!**

---

## Development Roadmap

### PHASE 1: Setup ✅
- [x] 1. Install Flutter SDK and set up development environment
- [x] 2. Create new Flutter project: `growatt_control_app`
- [x] 3. Add dependencies (http, provider, shared_preferences)

### PHASE 2: Project Structure ✅
- [x] 4. Create folder structure:
  - `lib/models/` - Data models
  - `lib/services/` - API service
  - `lib/providers/` - State management
  - `lib/screens/` - Screens
  - `lib/widgets/` - Reusable components

### PHASE 3: Data & API Layer ✅
- [x] 5. Create models (Device, ApiResponse)
- [x] 6. Implement ApiService class:
  - Device List endpoint
  - Device status endpoint
  - setOnOrOff endpoint
  - Error handling

### PHASE 4: UI Screens ✅
- [x] 7. Settings screen (token + region configuration)
- [x] 8. Devices list screen (main screen)
  - AppBar with refresh and settings
  - ListView with device cards
  - Pull-to-refresh
  - Loading states

### PHASE 5: Device Card Component ✅
- [x] 9. Create DeviceCard widget:
  - Device info (name, SN, type)
  - Status indicator (online/offline)
  - Power status
  - On/Off switch

### PHASE 6: State Management ✅
- [x] 10. Provider setup:
  - Config provider (token, region)
  - Devices provider
  - Loading/error states

### PHASE 7: Polish & Bug Fixes ✅
- [x] 11. Rate limiting (5 sec cooldown)
- [x] 12. Error messages (SnackBars)
- [x] 13. Fix status colors (Waiting=orange, Normal=green, Fault=red)
- [x] 14. Fix copyWith() bug (nullable fields)
- [x] 15. Add total power display
- [x] 16. Add live updating timestamps
- [x] 17. Debug logging for troubleshooting
- [ ] 18. Icon and app name (optional)
- [ ] 19. Test on emulator/device
- [ ] 20. Build APK

---

## Current Status

**Phase**: Implementation complete - Ready for testing
**Last worked**: 2025-11-11
**Next step**: Build APK and test on Android device
**Project location**: `C:\Dev\growatt_control_app`

### Completed Tasks

- Technology choice made (Flutter)
- Roadmap created
- Architecture decisions documented
- Flutter project created on C:\Dev (local drive for better performance)
- Dependencies added (http, provider, shared_preferences)
- Project structure created (models, services, providers, screens, widgets)
- Models implemented (Device, ApiResponse)
- ApiService implemented with all endpoints
- Providers implemented (ConfigProvider, DevicesProvider)
- Settings screen implemented
- Devices list screen implemented
- DeviceCard widget implemented
- Main.dart updated with Provider setup
- **Fixed endpoint bug**: Changed from `/getDeviceList` to `/queryDeviceList`
- **Fixed status fetching**: Added `queryLastData()` calls for each device
- **Implemented caching**: Device data cached for 5 minutes (respects rate limits)
- **Rate limit handling**: 5-second cooldowns for refresh and toggle operations
- **Optimistic UI updates**: Instant feedback when toggling devices
- **Live timestamps**: "Xm ago" labels update every 30 seconds
- **Status color fix**: Waiting=orange, Normal=green, Fault=red
- **copyWith() bug fix**: Sentinel value pattern for nullable fields
- **Total power display**: Aggregate current power and today's energy
- **Debug logging**: Added for troubleshooting status issues
- Code analysis passed (0 errors, 0 warnings)

---

## Design Decisions & Insights

### Decision 1: Flutter over React Native
**Date**: 2025-11-10
**Choice**: Flutter
**Reason**:
- Better built-in Material Design widgets
- Faster development with hot reload
- Simpler for this use case
- Single codebase for Android + iOS

### Decision 2: No custom server
**Date**: 2025-11-10
**Choice**: Direct connection to Growatt API
**Reason**:
- User doesn't have a server available
- Not needed - app can communicate directly with Growatt API
- Token stored securely in shared_preferences

### Decision 3: Sentinel value pattern for copyWith()
**Date**: 2025-11-11
**Choice**: Use `_keep` sentinel value for nullable parameters
**Reason**:
- Dart's `??` operator can't distinguish between "not passed" and "explicitly null"
- Without this, `copyWith(statusText: null)` would keep old value instead of updating
- Sentinel pattern allows proper null updates while maintaining backwards compatibility

### Insight 1: Rate Limiting
**Date**: 2025-11-10
**Finding**: Growatt API has rate limits
- Device list: max every 5 seconds
- Device control: max every 5 seconds
- Batch info: max every 5 minutes
**Action**: UI disables refresh buttons for 5 seconds + shows countdown

### Insight 2: Noah devices
**Date**: 2025-11-10
**Finding**: Noah-type devices do NOT support power control
**Action**: Hide on/off switch for Noah devices

### Insight 3: Different device types
**Date**: 2025-11-10
**Finding**: Different device types (inv, storage, sph, spa, min, max, wit, sph-s, noah)
**Action**: Device type must be sent with API calls

### Insight 4: Status codes vs status text
**Date**: 2025-11-11
**Finding**: `queryDeviceList` doesn't return status field - need `queryLastData`
**Action**: Fetch detailed data for each device with smart caching (5-minute cache)

### Insight 5: Status interpretation
**Date**: 2025-11-11
**Finding**: Status 0 = "Waiting" (not offline!), Status 1 = "Normal", Status 3 = "Fault"
**Action**:
- Color codes: Orange=Waiting, Green=Normal/Producing, Red=Fault
- Switch behavior: Disabled for Fault, enabled for Waiting/Normal
- Display API statusText directly instead of "Online/Offline"

### Insight 6: copyWith() with null values
**Date**: 2025-11-11
**Finding**: `statusText: statusText ?? this.statusText` prevents updating to null
**Action**: Implement sentinel value pattern with `_keep` constant

---

## API Information (Quick Reference)

### Authentication
- Token: 32-character verification code
- Token in HTTP header for each call
- User enters token via Settings screen

### Base URLs
- China: `https://openapi-cn.growatt.com`
- International: `https://openapi.growatt.com`
- North America: `https://openapi-us.growatt.com`
- Australia/NZ: `http://openapi-au.growatt.com`

### Key Endpoints
1. `/v4/new-api/queryDeviceList` - List of devices
2. `/v4/new-api/queryLastData` - Device status and telemetry
3. `/v4/new-api/setOnOrOff` - Turn on/off

### Error Codes
- `0` - Success
- `2` - Invalid token
- `4` - Device not found
- `5` - Device offline
- `100-102` - Rate limiting

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.1.1
  shared_preferences: ^2.2.2
```

---

## App Structure

```
C:\Dev\growatt_control_app\
├── lib/
│   ├── models/
│   │   ├── device.dart           # Device data model
│   │   └── api_response.dart     # API response wrapper
│   ├── services/
│   │   └── api_service.dart      # Growatt API communication
│   ├── providers/
│   │   ├── config_provider.dart  # Token & region storage
│   │   └── devices_provider.dart # Devices state management
│   ├── screens/
│   │   ├── devices_screen.dart   # Main screen
│   │   └── settings_screen.dart  # Settings screen
│   ├── widgets/
│   │   └── device_card.dart      # Device card component
│   └── main.dart                 # App entry point
├── docs/
│   ├── DEVELOPMENT.md            # This file
│   ├── API_REFERENCE.md          # API documentation
│   └── CHANGELOG.md              # Version history
├── pubspec.yaml                  # Dependencies
└── android/                      # Android config
```

---

## Building & Testing

### Development Mode (Testing)
```bash
cd C:\Dev\growatt_control_app
flutter run
```

### Build APK for Android
```bash
cd C:\Dev\growatt_control_app
flutter build apk --release
```
APK location: `build\app\outputs\flutter-apk\app-release.apk`

### Install APK on Android
1. Copy `app-release.apk` to your phone
2. Open the file on your phone
3. Allow installation from unknown sources (if asked)
4. Install the app

### First Use
1. Open the app
2. Tap Settings
3. Enter your Growatt API token (32 characters)
4. Select your region
5. Tap "Save Settings"
6. App automatically loads your devices

---

## Troubleshooting Development Issues

### Issue: CORS errors in Flutter Web
**Solution**: App only works on Android/iOS, not web (Growatt API doesn't allow CORS)

### Issue: Slow performance on network drive
**Solution**: Moved project to local drive (C:\Dev) for faster builds

### Issue: Devices showing offline when they're not
**Solution**: `queryDeviceList` doesn't include status - need to call `queryLastData` per device

### Issue: Switch disabled for Waiting devices
**Solution**: Changed logic - switch enabled for Waiting (can turn on), disabled for Fault only

### Issue: "Last updated" timestamp static
**Solution**: Added timer that calls `notifyListeners()` every 30 seconds

### Issue: Device shows "Unknown" status
**Solution**: Fixed `copyWith()` bug with sentinel value pattern

---

## Future Improvements

- [ ] Historical data graphs
- [ ] Push notifications for status changes
- [ ] Widget for home screen
- [ ] iOS support
- [ ] Dark mode
- [ ] Multiple accounts support
- [ ] Export energy data to CSV

---

**Last update**: 2025-11-11
**Status**: Ready for APK build and testing
