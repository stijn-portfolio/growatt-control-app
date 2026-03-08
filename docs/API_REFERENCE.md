# Growatt API Reference

## Overview

This document provides technical details for working with the Growatt OpenAPI v4.

## API Configuration

### Base URLs by Region
- **China**: `https://openapi-cn.growatt.com`
- **International**: `https://openapi.growatt.com`
- **North America**: `https://openapi-us.growatt.com`
- **Australia/NZ**: `http://openapi-au.growatt.com`

### Authentication
All API calls require a token in the HTTP header:
```
token: YOUR_32_CHARACTER_TOKEN_HERE
Content-Type: application/x-www-form-urlencoded
```

### Getting an API Token
1. Go to [Growatt OSS Portal](https://oss.growatt.com)
2. Create an account or log in
3. Configure your installer account
4. Add your devices to the account
5. Generate an API token (32-character verification code)

---

## API Endpoints

### 1. Get Device List ✅

**Endpoint**: `/v4/new-api/queryDeviceList`
**Method**: POST
**Rate Limit**: Max once every 5 seconds

**Request**:
```bash
curl -X POST "https://openapi.growatt.com/v4/new-api/queryDeviceList" \
  -H "token: YOUR_TOKEN_HERE" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "page=1"
```

**Response**:
```json
{
  "code": 0,
  "data": {
    "count": 2,
    "data": [
      {
        "deviceType": "inv",
        "deviceSn": "DEVICE_SERIAL_NUMBER_1",
        "datalogSn": "DATALOGGER_SN_1"
      },
      {
        "deviceType": "inv",
        "deviceSn": "DEVICE_SERIAL_NUMBER_2",
        "datalogSn": "DATALOGGER_SN_2"
      }
    ]
  },
  "message": "SUCCESSFUL_OPERATION"
}
```

---

### 2. Get Device Status & Data ✅

**Endpoint**: `/v4/new-api/queryLastData`
**Method**: POST
**Rate Limit**: Max once every 5 minutes

**Request**:
```bash
curl -X POST "https://openapi.growatt.com/v4/new-api/queryLastData" \
  -H "token: YOUR_TOKEN_HERE" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "deviceType=inv" \
  -d "deviceSn=YOUR_DEVICE_SN"
```

**Important Response Fields**:
- `status` - Device status: 0=Waiting, 1=Normal, 3=Fault
- `statusText` - Human-readable status: "Waiting", "Normal", "Fault"
- `pac` - Current AC output power (W)
- `ppv` - Current PV input power (W)
- `powerToday` - Energy produced today (kWh)
- `powerTotal` - Total energy produced (kWh)
- `temperature` - Inverter temperature (°C)
- `time` - Timestamp of measurement

**Example Response** (abbreviated):
```json
{
  "code": 0,
  "data": {
    "inv": [
      {
        "inverterId": "DEVICE_SN",
        "time": "2025-11-11 07:53:09",
        "status": 0,
        "statusText": "Waiting",
        "pac": 0.0,
        "ppv": 0.0,
        "powerToday": 0.0,
        "powerTotal": 14411.3,
        "temperature": 26.3,
        "vpv1": 184.2,
        "ipv1": 0.0,
        "vacr": 227.7,
        "fac": 49.99
      }
    ]
  },
  "message": "SUCCESSFUL_OPERATION"
}
```

---

### 3. Turn Device On ✅

**Endpoint**: `/v4/new-api/setOnOrOff`
**Method**: POST
**Rate Limit**: Max once every 5 seconds

**Request**:
```bash
curl -X POST "https://openapi.growatt.com/v4/new-api/setOnOrOff" \
  -H "token: YOUR_TOKEN_HERE" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "deviceSn=YOUR_DEVICE_SN" \
  -d "deviceType=inv" \
  -d "value=1"
```

**Response**:
```json
{
  "code": 0,
  "data": null,
  "message": "PARAMETER_SETTING_SUCCESSFUL"
}
```

---

### 4. Turn Device Off ✅

**Endpoint**: `/v4/new-api/setOnOrOff`
**Method**: POST
**Rate Limit**: Max once every 5 seconds

**Request**:
```bash
curl -X POST "https://openapi.growatt.com/v4/new-api/setOnOrOff" \
  -H "token: YOUR_TOKEN_HERE" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "deviceSn=YOUR_DEVICE_SN" \
  -d "deviceType=inv" \
  -d "value=0"
```

**Response**:
```json
{
  "code": 0,
  "data": null,
  "message": "PARAMETER_SETTING_SUCCESSFUL"
}
```

**Note**: May timeout if device is not responsive (e.g., at night, low sunlight):
```json
{
  "code": 16,
  "data": null,
  "message": "PARAMETER_SETTING_RESPONSE_TIMEOUT"
}
```

---

## Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Operation succeeded |
| 2 | Invalid token | Refresh token |
| 4 | Device not found | Check device SN |
| 5 | Device offline | Wait for device to come online |
| 12 | No permission | Device not linked to token |
| 16 | Response timeout | Retry operation |
| 100-102 | Rate limiting | Wait, adjust request interval |

---

## Rate Limits Summary

| Endpoint | Limit | Cache Strategy |
|----------|-------|----------------|
| queryDeviceList | 5 seconds | Refresh only when needed |
| queryLastData | 5 minutes | Cache data per device |
| setOnOrOff | 5 seconds | Show cooldown timer |

---

## Device Types

The API supports multiple device types:
- `inv` - Standard inverters
- `storage` - Storage systems
- `max` - MAX series devices
- `sph` - SPH series (hybrid inverters)
- `spa` - SPA series
- `min` - MIN series
- `wit` - WIT series
- `sph-s` - SPH-S series
- `noah` - NOAH 2000 (does NOT support power control)

**Important**: Always include the correct `deviceType` in API requests.

---

## Device Status Codes

| Status | Text | Meaning | Color |
|--------|------|---------|-------|
| 0 | Waiting | Device connected, waiting for sunlight | Orange |
| 1 | Normal | Device actively producing power | Green |
| 3 | Fault | Device has an error | Red |

---

## Best Practices

### 1. Respect Rate Limits
- Implement cooldown timers in your UI
- Cache data when possible
- Show countdown to users

### 2. Error Handling
- Always check response `code` field
- Provide user-friendly error messages
- Implement retry logic for timeouts

### 3. Device Status
- Call `queryDeviceList` first to get device list
- Then call `queryLastData` for each device
- Cache `queryLastData` results for 5 minutes

### 4. Power Control
- Verify device type supports control (no Noah devices)
- Handle timeouts gracefully (especially at night)
- Provide feedback to users (success/failure messages)

### 5. Token Security
- Never hardcode tokens in your app
- Store tokens securely (e.g., secure storage)
- Allow users to input their own token via settings

---

## Example Flutter Implementation

```dart
Future<Map<String, dynamic>> getDeviceData(String deviceSn) async {
  final response = await http.post(
    Uri.parse('https://openapi.growatt.com/v4/new-api/queryLastData'),
    headers: {
      'token': storedToken,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'deviceType': 'inv',
      'deviceSn': deviceSn,
    },
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    if (jsonData['code'] == 0) {
      return jsonData['data']['inv'][0];
    } else {
      throw Exception(jsonData['message']);
    }
  } else {
    throw Exception('HTTP ${response.statusCode}');
  }
}
```

---

## Troubleshooting

### No devices returned
- Verify OSS account has devices registered
- Check device SN is correct
- Ensure devices are linked to your OSS account

### Invalid token error
- Token may have expired - generate new one
- Check token is exactly 32 characters
- Verify correct region selected

### Device offline
- Check device is actually powered and connected
- Verify datalogger has internet connection
- Wait a few minutes and retry

### Response timeout
- Normal at night or low sunlight conditions
- Device may not be responsive
- Try again during daylight hours

---

## Additional Resources

- **OSS Portal**: https://oss.growatt.com/index
- **API Version**: v4 (new-api)
- **Format**: JSON responses with UTF-8 encoding
- **Date Format**: `YYYY-MM-DD HH:mm:ss`

---

**Last updated**: 2025-11-11
