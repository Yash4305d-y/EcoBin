/// Centralized architectural constants for networking, polling, and limits.
abstract final class AppConstants {
  /// Strict HTTP network request timeout (5.0 seconds).
  static const Duration httpTimeout = Duration(seconds: 5);

  /// Periodic background status telemetry poll interval (5.0 seconds).
  static const Duration statusPollInterval = Duration(seconds: 5);

  /// Number of consecutive poll failures required to transition to offline state.
  static const int maxConsecutivePollFailures = 3;

  /// Bounded memory limit for debug log entries.
  static const int maxDebugLogs = 50;

  /// Default ESP8266/ESP32 target IPv4 address.
  static const String defaultEsp32Ip = '10.236.242.197';

  /// Measured distance (cm) from downward-facing fill sensor to bin bottom when empty.
  /// (Dustbin calibrated height is 20.0 cm).
  static const double defaultEmptyDistanceCm = 20.0;

  /// Threshold (cm) from fill sensor to intended full capacity level (3.0 cm).
  static const double defaultFullDistanceCm = 3.0;
}
