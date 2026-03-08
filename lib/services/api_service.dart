import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../models/api_response.dart';

enum Region {
  china,
  international,
  northAmerica,
  australia,
}

class ApiService {
  final String token;
  final Region region;

  ApiService({
    required this.token,
    required this.region,
  });

  String get baseUrl {
    switch (region) {
      case Region.china:
        return 'https://openapi-cn.growatt.com';
      case Region.international:
        return 'https://openapi.growatt.com';
      case Region.northAmerica:
        return 'https://openapi-us.growatt.com';
      case Region.australia:
        return 'http://openapi-au.growatt.com';
    }
  }

  Map<String, String> get headers {
    return {
      'token': token,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  /// Get list of devices accessible with the token
  Future<ApiResponse<List<Device>>> getDeviceList() async {
    try {
      final url = Uri.parse('$baseUrl/v4/new-api/queryDeviceList');
      final body = {'page': '1'};

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        return ApiResponse.fromJson(
          jsonData,
          (data) {
            if (data is Map && data['data'] is List) {
              return (data['data'] as List)
                  .map((item) => Device.fromJson(item))
                  .toList();
            }
            return <Device>[];
          },
        );
      } else {
        return ApiResponse(
          code: -1,
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: 'Network error: $e',
      );
    }
  }

  /// Get last detailed data for a device (includes status, power, etc.)
  Future<ApiResponse<Map<String, dynamic>>> queryLastData({
    required String deviceSn,
    required String deviceType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/v4/new-api/queryLastData');
      final body = {
        'deviceSn': deviceSn,
        'deviceType': deviceType,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        return ApiResponse.fromJson(
          jsonData,
          (data) {
            // API returns data wrapped in device type key (e.g., "inv": [...])
            if (data is Map) {
              final deviceData = data[deviceType];
              if (deviceData is List && deviceData.isNotEmpty) {
                return deviceData.first as Map<String, dynamic>;
              }
            }
            return <String, dynamic>{};
          },
        );
      } else {
        return ApiResponse(
          code: -1,
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: 'Network error: $e',
      );
    }
  }

  /// Turn device on or off
  /// value: 1 = on, 0 = off
  Future<ApiResponse<String>> setDeviceOnOrOff({
    required String deviceSn,
    required String deviceType,
    required int value, // 1 = on, 0 = off
  }) async {
    try {
      final url = Uri.parse('$baseUrl/v4/new-api/setOnOrOff');
      final body = {
        'deviceSn': deviceSn,
        'deviceType': deviceType,
        'value': value.toString(),
      };

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ApiResponse.fromJson(jsonData, (data) => data.toString());
      } else {
        return ApiResponse(
          code: -1,
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: 'Network error: $e',
      );
    }
  }

  /// Get batch device information (max 100 devices)
  Future<ApiResponse<List<Map<String, dynamic>>>> getBatchDeviceInfo(
    List<String> deviceSns,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/v4/new-api/getBatchDeviceInfo');
      final body = {'deviceSnList': deviceSns.join(',')};

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        return ApiResponse.fromJson(
          jsonData,
          (data) {
            if (data is List) {
              return data.map((item) => item as Map<String, dynamic>).toList();
            }
            return <Map<String, dynamic>>[];
          },
        );
      } else {
        return ApiResponse(
          code: -1,
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: 'Network error: $e',
      );
    }
  }

  static String regionToString(Region region) {
    switch (region) {
      case Region.china:
        return 'China';
      case Region.international:
        return 'International';
      case Region.northAmerica:
        return 'North America';
      case Region.australia:
        return 'Australia/NZ';
    }
  }

  static Region regionFromString(String value) {
    switch (value) {
      case 'China':
        return Region.china;
      case 'North America':
        return Region.northAmerica;
      case 'Australia/NZ':
        return Region.australia;
      default:
        return Region.international;
    }
  }
}
