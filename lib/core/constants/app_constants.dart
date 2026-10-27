/// Centralized architectural constants for networking, polling, and limits.
abstract final class AppConstants {
  /// Strict HTTP network request timeout (3.0 seconds).
  static const Duration httpTimeout = Duration(seconds: 3);

  /// Periodic background status telemetry poll interval (5.0 seconds).
  static const Duration statusPollInterval = Duration(seconds: 5);

  /// Number of consecutive poll failures required to transition to offline state.
  static const int maxConsecutivePollFailures = 3;

  /// Bounded memory limit for debug log entries.
  static const int maxDebugLogs = 50;

  /// Default ESP32 factory SoftAP IPv4 address.
  static const String defaultEsp32Ip = '192.168.4.1';
}
