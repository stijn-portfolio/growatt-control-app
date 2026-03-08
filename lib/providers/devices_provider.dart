import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../services/api_service.dart';

class DevicesProvider with ChangeNotifier {
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastRefresh; // Last time queryDeviceList was called
  DateTime? _lastToggle; // Last time setOnOrOff was called
  Timer? _cooldownTimer;
  Timer? _uiUpdateTimer; // Timer for updating "Xm ago" labels

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefresh => _lastRefresh;
  DateTime? get lastToggle => _lastToggle;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  bool get canRefresh {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!).inSeconds >= 5;
  }

  /// Check if any device will actually get fresh data from API
  /// (Returns false if all devices have data < 5 minutes old)
  bool get willFetchFreshData {
    if (_devices.isEmpty) return true;
    final now = DateTime.now();
    return _devices.any((device) =>
        device.lastUpdated == null ||
        now.difference(device.lastUpdated!).inMinutes >= 5);
  }

  /// Get seconds until next device data can be refreshed
  int get nextFreshDataIn {
    if (_devices.isEmpty) return 0;
    final now = DateTime.now();

    // Find the device that was updated most recently
    DateTime? mostRecent;
    for (final device in _devices) {
      if (device.lastUpdated != null) {
        if (mostRecent == null || device.lastUpdated!.isAfter(mostRecent)) {
          mostRecent = device.lastUpdated;
        }
      }
    }

    if (mostRecent == null) return 0;

    final elapsed = now.difference(mostRecent).inSeconds;
    final remainingSeconds = (300 - elapsed).clamp(0, 300); // 300 sec = 5 min
    return remainingSeconds;
  }

  bool get canToggle {
    if (_lastToggle == null) return true;
    return DateTime.now().difference(_lastToggle!).inSeconds >= 5;
  }

  int get refreshCooldownSeconds {
    if (_lastRefresh == null) return 0;
    final elapsed = DateTime.now().difference(_lastRefresh!).inSeconds;
    return (5 - elapsed).clamp(0, 5);
  }

  int get toggleCooldownSeconds {
    if (_lastToggle == null) return 0;
    final elapsed = DateTime.now().difference(_lastToggle!).inSeconds;
    return (5 - elapsed).clamp(0, 5);
  }

  double get totalCurrentPower {
    return _devices.fold(0.0, (sum, device) => sum + (device.pac ?? 0));
  }

  double get totalPowerToday {
    return _devices.fold(0.0, (sum, device) => sum + (device.powerToday ?? 0));
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Keep running if:
      // - 5-second cooldown active (canRefresh or canToggle is false)
      // - OR devices have cached data that's not ready for refresh yet
      final needsTimer = !canRefresh || !canToggle || !willFetchFreshData;

      if (!needsTimer) {
        timer.cancel();
        _cooldownTimer = null;
      }
      notifyListeners();
    });
  }

  void _startUiUpdateTimer() {
    _uiUpdateTimer?.cancel();
    // Update UI every 30 seconds to refresh "Xm ago" labels
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      notifyListeners(); // Triggers rebuild of all listening widgets
    });
  }

  Future<void> loadDevices(ApiService apiService) async {
    if (!canRefresh) {
      _errorMessage = 'Please wait 5 seconds between refreshes';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Get device list
      final response = await apiService.getDeviceList();

      if (response.isSuccess && response.data != null) {
        _devices = response.data!;
        _lastRefresh = DateTime.now();
        _errorMessage = null;
        _startCooldownTimer();
        _startUiUpdateTimer(); // Start timer for updating "Xm ago" labels

        // Step 2: Fetch detailed data for each device (respecting 5-minute rate limit)
        final updatedDevices = <Device>[];
        final now = DateTime.now();

        for (final device in _devices) {
          // Check if device data needs refresh (> 5 minutes old)
          final needsRefresh = device.lastUpdated == null ||
              now.difference(device.lastUpdated!).inMinutes >= 5;

          if (needsRefresh) {
            try {
              final dataResponse = await apiService.queryLastData(
                deviceSn: device.deviceSn,
                deviceType: device.deviceType,
              );

              if (dataResponse.isSuccess && dataResponse.data != null) {
                final data = dataResponse.data!;
                debugPrint(
                  'Device ${device.deviceSn}: API returned status=${data['status']}, statusText=${data['statusText']}',
                );
                // Update device with latest data
                final updatedDevice = device.copyWith(
                  status: data['status'] as int?,
                  statusText: data['statusText'] as String?,
                  pac: (data['pac'] as num?)?.toDouble(),
                  powerToday: (data['powerToday'] as num?)?.toDouble(),
                  powerTotal: (data['powerTotal'] as num?)?.toDouble(),
                  temperature: (data['temperature'] as num?)?.toDouble(),
                  lastUpdated: now,
                );
                updatedDevices.add(updatedDevice);
              } else {
                // Keep original device if fetch fails
                updatedDevices.add(device);
                debugPrint(
                  'Failed to fetch data for ${device.deviceSn}: ${dataResponse.errorMessage}',
                );
              }
            } catch (e) {
              // Keep original device if fetch fails
              updatedDevices.add(device);
              debugPrint('Error fetching data for ${device.deviceSn}: $e');
            }
          } else {
            // Use cached data (< 5 minutes old)
            updatedDevices.add(device);
            debugPrint(
              'Using cached data for ${device.deviceSn} (${now.difference(device.lastUpdated!).inMinutes}m old) - statusText: ${device.statusText}',
            );
          }
        }

        _devices = updatedDevices;
      } else {
        _errorMessage = response.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Failed to load devices: $e';
      debugPrint('Error loading devices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleDevice(
    ApiService apiService,
    Device device,
    bool turnOn,
  ) async {
    // Check if device is Noah type (doesn't support power control)
    if (device.isNoahDevice) {
      _errorMessage = 'Noah devices do not support power control';
      notifyListeners();
      return false;
    }

    if (!canToggle) {
      _errorMessage = 'Please wait ${toggleCooldownSeconds}s between operations';
      notifyListeners();
      return false;
    }

    try {
      // Optimistic update: update local state immediately
      final index = _devices.indexWhere((d) => d.deviceSn == device.deviceSn);
      if (index != -1) {
        _devices[index] = device.copyWith(
          status: turnOn ? 1 : 0,
        );
        notifyListeners();
      }

      final response = await apiService.setDeviceOnOrOff(
        deviceSn: device.deviceSn,
        deviceType: device.deviceType,
        value: turnOn ? 1 : 0,
      );

      _lastToggle = DateTime.now();
      _startCooldownTimer();

      if (response.isSuccess) {
        _errorMessage = null;
        // Don't automatically refresh - user can manually refresh if needed
        // This respects rate limits better
        return true;
      } else {
        // Revert optimistic update on failure
        if (index != -1) {
          _devices[index] = device.copyWith(
            status: turnOn ? 0 : 1, // Revert
          );
        }
        _errorMessage = response.errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to control device: $e';
      debugPrint('Error controlling device: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _devices = [];
    _isLoading = false;
    _errorMessage = null;
    _lastRefresh = null;
    _lastToggle = null;
    notifyListeners();
  }
}
