/// Base exception for EcoBin device operations.
sealed class EcoBinException implements Exception {
  const EcoBinException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thrown when physical connection or network transport fails (timeout, socket error).
class DeviceConnectionException extends EcoBinException {
  const DeviceConnectionException(
    super.message, {
    this.isTimeout = false,
    this.originalError,
  });

  final bool isTimeout;
  final Object? originalError;
}

/// Thrown when the ESP32 responds with a non-success HTTP status code (4xx, 5xx).
class DeviceApiException extends EcoBinException {
  const DeviceApiException(
    super.message, {
    required this.statusCode,
    this.endpoint,
    this.responseBody,
  });

  final int statusCode;
  final String? endpoint;
  final String? responseBody;
}

/// Thrown when response JSON is malformed, not a Map, or missing required fields.
class DeviceDataException extends EcoBinException {
  const DeviceDataException(super.message, {this.originalError});

  final Object? originalError;
}
