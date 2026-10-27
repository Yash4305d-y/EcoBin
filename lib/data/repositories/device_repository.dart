import '../models/app_alert.dart';
import '../models/debug_log_entry.dart';
import '../models/device_event.dart';
import '../models/device_status.dart';

/// Contract for interacting with the EcoBin device (mock or real HTTP).
abstract class DeviceRepository {
  /// Emits updates whenever the device status changes.
  Stream<DeviceStatus> watchStatus();

  /// Retrieves the current snapshot of device status.
  DeviceStatus getCurrentStatus();

  /// Probes device health (`GET /api/health`).
  Future<Map<String, dynamic>> checkHealth();

  /// Issues a command to open the lid.
  Future<void> openLid();

  /// Issues a command to close the lid.
  Future<void> closeLid();

  /// Updates the bin operating mode.
  Future<void> setOperatingMode(OperatingMode mode);

  /// Simulates/updates fill level (applicable to mock/simulation).
  Future<void> setFillPercentage(double? percentage);

  /// Retrieves recent activity events.
  Future<List<DeviceEvent>> getEvents();

  /// Retrieves active in-app alerts.
  Future<List<AppAlert>> getAlerts();

  /// Dismisses an alert.
  Future<void> dismissAlert(String alertId);

  /// Retrieves recent debug log records.
  Future<List<DebugLogEntry>> getDebugLogs();

  /// Clears debug log records.
  void clearDebugLogs();

  /// Pauses polling loops (e.g. when app moves to background).
  void pausePolling();

  /// Resumes polling loops and triggers an immediate refresh.
  void resumePolling();

  /// Cleans up timers, controllers, and resources.
  void dispose();
}
