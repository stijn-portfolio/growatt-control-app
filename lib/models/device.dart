class Device {
  final String deviceSn;
  final String deviceType;
  final String? datalogSn;
  final String? createDate;
  final String? deviceAilas;
  final int status; // 0 = waiting, 1 = normal (producing), 3 = fault
  final int? lost; // Device connection status

  // Last data fields (from queryLastData)
  final String? statusText; // "Waiting", "Normal", "Fault"
  final double? pac; // Current AC output power (W)
  final double? powerToday; // Today's energy generation (kWh)
  final double? powerTotal; // Total energy generation (kWh)
  final double? temperature; // Temperature (°C)
  final DateTime? lastUpdated; // When was this device data last fetched

  Device({
    required this.deviceSn,
    required this.deviceType,
    this.datalogSn,
    this.createDate,
    this.deviceAilas,
    this.status = 0,
    this.lost,
    this.statusText,
    this.pac,
    this.powerToday,
    this.powerTotal,
    this.temperature,
    this.lastUpdated,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceSn: json['deviceSn'] as String,
      deviceType: json['deviceType'] as String,
      datalogSn: json['datalogSn'] as String?,
      createDate: json['createDate'] as String?,
      deviceAilas: json['deviceAilas'] as String?,
      status: json['status'] as int? ?? 0,
      lost: json['lost'] as int?,
      statusText: json['statusText'] as String?,
      pac: (json['pac'] as num?)?.toDouble(),
      powerToday: (json['powerToday'] as num?)?.toDouble(),
      powerTotal: (json['powerTotal'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceSn': deviceSn,
      'deviceType': deviceType,
      'datalogSn': datalogSn,
      'createDate': createDate,
      'deviceAilas': deviceAilas,
      'status': status,
      'lost': lost,
      'statusText': statusText,
      'pac': pac,
      'powerToday': powerToday,
      'powerTotal': powerTotal,
      'temperature': temperature,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Create a copy of this Device with updated fields
  /// For nullable fields, pass the sentinel value _keep to retain the old value
  Device copyWith({
    String? deviceSn,
    String? deviceType,
    String? datalogSn,
    String? createDate,
    String? deviceAilas,
    int? status,
    int? lost,
    Object? statusText = _keep,
    Object? pac = _keep,
    Object? powerToday = _keep,
    Object? powerTotal = _keep,
    Object? temperature = _keep,
    Object? lastUpdated = _keep,
  }) {
    return Device(
      deviceSn: deviceSn ?? this.deviceSn,
      deviceType: deviceType ?? this.deviceType,
      datalogSn: datalogSn ?? this.datalogSn,
      createDate: createDate ?? this.createDate,
      deviceAilas: deviceAilas ?? this.deviceAilas,
      status: status ?? this.status,
      lost: lost ?? this.lost,
      statusText: statusText == _keep ? this.statusText : statusText as String?,
      pac: pac == _keep ? this.pac : pac as double?,
      powerToday: powerToday == _keep ? this.powerToday : powerToday as double?,
      powerTotal: powerTotal == _keep ? this.powerTotal : powerTotal as double?,
      temperature:
          temperature == _keep ? this.temperature : temperature as double?,
      lastUpdated:
          lastUpdated == _keep ? this.lastUpdated : lastUpdated as DateTime?,
    );
  }

  // Status getters
  bool get isWaiting => status == 0;
  bool get isProducing => status == 1;
  bool get hasFault => status == 3;
  bool get isConnected => status == 0 || status == 1;

  // Legacy getter - device is actively producing
  bool get isOnline => status == 1;

  bool get isNoahDevice => deviceType.toLowerCase() == 'noah';
  String get displayName => deviceAilas ?? deviceSn;

  @override
  String toString() {
    return 'Device(sn: $deviceSn, type: $deviceType, name: $displayName, online: $isOnline)';
  }
}

// Sentinel value for copyWith to distinguish between "not provided" and "null"
const _keep = _Keep();

class _Keep {
  const _Keep();
}
