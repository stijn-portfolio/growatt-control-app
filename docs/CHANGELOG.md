# Changelog

All notable changes to the Growatt Control App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Historical data graphs
- Push notifications for status changes
- Home screen widget
- iOS support
- Dark mode theme
- Multi-account support
- CSV export for energy data

## [1.0.0] - 2025-11-11

### Added
- Initial release
- **Device monitoring**: View real-time status, power output, and energy production
- **Remote control**: Turn inverters on/off remotely
- **Multi-device support**: Manage multiple inverters in one app
- **Smart caching**: Device data cached for 5 minutes to respect API rate limits
- **Rate limit protection**: Built-in 5-second cooldowns with countdown timers
- **Status indicators**:
  - 🟢 Green for producing (Normal)
  - 🟠 Orange for waiting (connected but no sunlight)
  - 🔴 Red for fault/offline
- **Aggregate statistics**: Total current power and today's energy across all devices
- **Live timestamps**: "Xm ago" labels update automatically every 30 seconds
- **Optimistic UI updates**: Instant feedback when toggling devices
- **Settings screen**: Configure API token and region
- **Error handling**: User-friendly error messages with retry options
- **Pull-to-refresh**: Manual refresh with cooldown protection
- **Device details**:
  - Current power (W)
  - Today's energy (kWh)
  - Total energy (kWh)
  - Temperature (°C)
  - Last update time

### Technical Details
- Flutter 3.x framework
- Provider state management
- HTTP client for API communication
- SharedPreferences for local config storage
- Support for all Growatt inverter types (inv, storage, sph, spa, min, max, wit, sph-s)
- Noah device detection (power control disabled, as per API limitations)

### Fixed
- Correct API endpoint usage (`queryDeviceList` instead of `getDeviceList`)
- Device status now properly fetched via `queryLastData` endpoint
- Status colors correctly reflect device state (Waiting vs Offline distinction)
- Nullable field updates in Device model (sentinel value pattern)
- Switch behavior: enabled for Waiting state, disabled only for Fault state
- Live timestamp updates without per-card timers

### Known Limitations
- Noah-type devices do not support power control (API limitation)
- No support for changing advanced inverter parameters
- Historical data not available yet
- Android only (iOS coming in future)

---

## Version History

### [1.0.0] - 2025-11-11
First stable release with core functionality.

---

**Legend**:
- `Added` for new features
- `Changed` for changes in existing functionality
- `Deprecated` for soon-to-be removed features
- `Removed` for now removed features
- `Fixed` for any bug fixes
- `Security` for vulnerability fixes
