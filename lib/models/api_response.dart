class ApiResponse<T> {
  final int code;
  final T? data;
  final String? message;

  ApiResponse({
    required this.code,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
    );
  }

  bool get isSuccess => code == 0;
  bool get isInvalidToken => code == 2;
  bool get isDeviceNotFound => code == 4;
  bool get isDeviceOffline => code == 5;
  bool get isRateLimited => code >= 100 && code <= 102;

  String get errorMessage {
    switch (code) {
      case 0:
        return 'Success';
      case 2:
        return 'Invalid token';
      case 4:
        return 'Device not found';
      case 5:
        return 'Device offline';
      case 100:
      case 101:
      case 102:
        return 'Rate limit exceeded. Please wait.';
      default:
        return message ?? 'Unknown error (code: $code)';
    }
  }

  @override
  String toString() {
    return 'ApiResponse(code: $code, message: $errorMessage)';
  }
}
