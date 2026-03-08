import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ConfigProvider with ChangeNotifier {
  static const String _tokenKey = 'growatt_token';
  static const String _regionKey = 'growatt_region';

  String? _token;
  Region _region = Region.international;
  bool _isLoading = true;

  String? get token => _token;
  Region get region => _region;
  bool get isLoading => _isLoading;
  bool get isConfigured => _token != null && _token!.isNotEmpty;

  ConfigProvider() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final regionString = prefs.getString(_regionKey);
      if (regionString != null) {
        _region = ApiService.regionFromString(regionString);
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveConfig(String token, Region region) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_regionKey, ApiService.regionToString(region));
      _token = token;
      _region = region;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving config: $e');
      throw Exception('Failed to save configuration');
    }
  }

  Future<void> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_regionKey);
      _token = null;
      _region = Region.international;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing config: $e');
      throw Exception('Failed to clear configuration');
    }
  }

  ApiService? getApiService() {
    if (_token == null || _token!.isEmpty) {
      return null;
    }
    return ApiService(token: _token!, region: _region);
  }
}
