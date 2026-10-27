import 'dart:async';

import '../models/app_alert.dart';
import '../models/debug_log_entry.dart';
import '../models/device_event.dart';
import '../models/device_status.dart';
import 'device_repository.dart';

/// In-memory implementation of [DeviceRepository] providing realistic,
/// responsive mock data and simulated state transitions.
///
/// All outputs are explicitly marked with `isDemo: true`.
class MockDeviceRepository implements DeviceRepository {
  MockDeviceRepository() {
    _status = DeviceStatus(
      isDemo: true,
      fillPercentage: 64.0, // Believable default fill level
      lidState: LidState.closed,
      mode: OperatingMode.automatic,
      todayOpenings: 18,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      deviceIp: '192.168.4.1 (Simulated SoftAP)',
      batteryPercentage: 92,
      wifiSignalDbm: -56,
    );

    _initSampleData();
  }

  late DeviceStatus _status;
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();

  final List<DeviceEvent> _events = [];
  final List<AppAlert> _alerts = [];
  final List<DebugLogEntry> _logs = [];

  void _initSampleData() {
    final now = DateTime.now();

    // Sample historical events (clearly labeled demo)
    _events.addAll([
      DeviceEvent(
        id: 'evt-1',
        type: DeviceEventType.lidClosed,
        title: 'Lid Closed',
        description: 'Automatic close timer expired after 5s.',
        timestamp: now.subtract(const Duration(minutes: 12)),
        isDemo: true,
      ),
      DeviceEvent(
        id: 'evt-2',
        type: DeviceEventType.lidOpened,
        title: 'Lid Opened',
        description: 'Triggered by ultrasonic hands-free proximity sensor.',
        timestamp: now.subtract(const Duration(minutes: 12, seconds: 5)),
        isDemo: true,
      ),
      DeviceEvent(
        id: 'evt-3',
        type: DeviceEventType.fillWarning,
        title: 'Fill Threshold Checked',
        description: 'Ultrasonic depth measurement recorded bin at 64% full.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        isDemo: true,
      ),
      DeviceEvent(
        id: 'evt-4',
        type: DeviceEventType.lidOpened,
        title: 'Manual Lid Operation',
        description: 'Lid opened via companion app manual control toggle.',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
        isDemo: true,
      ),
      DeviceEvent(
        id: 'evt-5',
        type: DeviceEventType.modeChanged,
        title: 'Operating Mode Set',
        description: 'Operating mode transitioned to Automatic trigger mode.',
        timestamp: now.subtract(const Duration(hours: 4)),
        isDemo: true,
      ),
    ]);

    // Sample in-app alerts
    _alerts.addAll([
      AppAlert(
        id: 'alert-1',
        title: 'Bin Capacity Advisory',
        message: 'Bin fill level has reached 64%. Emptying recommended soon to prevent overflow.',
        severity: AlertSeverity.warning,
        timestamp: now.subtract(const Duration(hours: 1)),
        isDemo: true,
      ),
      AppAlert(
        id: 'alert-2',
        title: 'Automatic Proximity Active',
        message: 'Ultrasonic detection is operational. Lid opens automatically when hand is detected within 20cm.',
        severity: AlertSeverity.info,
        timestamp: now.subtract(const Duration(hours: 3)),
        isDemo: true,
      ),
      AppAlert(
        id: 'alert-3',
        title: 'System Health Check',
        message: 'Simulated servo response, ultrasonic echo, and power telemetry nominal.',
        severity: AlertSeverity.info,
        timestamp: now.subtract(const Duration(hours: 6)),
        isDemo: true,
      ),
    ]);

    // Sample debug logs
    _logs.addAll([
      DebugLogEntry(
        id: 'log-1',
        timestamp: now.subtract(const Duration(minutes: 15)),
        source: 'CORE_INIT',
        message: 'MockDeviceRepository initialized in Demo Mode.',
        severity: LogSeverity.info,
      ),
      DebugLogEntry(
        id: 'log-2',
        timestamp: now.subtract(const Duration(minutes: 12)),
        source: 'SENSOR_PROXIMITY',
        message: 'Echo detected: 14cm < threshold (20cm). Opening lid.',
        severity: LogSeverity.action,
      ),
      DebugLogEntry(
        id: 'log-3',
        timestamp: now.subtract(const Duration(minutes: 11)),
        source: 'SERVO_ACTUATOR',
        message: 'PWM signal written: duty 90deg -> 0deg (Closed).',
        severity: LogSeverity.info,
      ),
      DebugLogEntry(
        id: 'log-4',
        timestamp: now.subtract(const Duration(minutes: 2)),
        source: 'TELEMETRY_POLL',
        message: 'Heartbeat ping: battery=92%, signal=-56dBm, fill=64%.',
        severity: LogSeverity.info,
      ),
    ]);
  }

  void _addLog(String source, String message, LogSeverity severity) {
    _logs.insert(
      0,
      DebugLogEntry(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        source: source,
        message: message,
        severity: severity,
        isDemo: true,
      ),
    );
  }

  @override
  Stream<DeviceStatus> watchStatus() async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  DeviceStatus getCurrentStatus() => _status;

  @override
  Future<void> openLid() async {
    _addLog(
      'CONTROLS',
      'Simulated command: openLid() requested.',
      LogSeverity.action,
    );

    // Transition to moving
    _status = _status.copyWith(
      lidState: LidState.moving,
      lastUpdated: DateTime.now(),
    );
    _statusController.add(_status);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Transition to open
    _status = _status.copyWith(
      lidState: LidState.open,
      todayOpenings: _status.todayOpenings + 1,
      lastUpdated: DateTime.now(),
    );
    _statusController.add(_status);

    _events.insert(
      0,
      DeviceEvent(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        type: DeviceEventType.lidOpened,
        title: 'Lid Opened (Manual Demo)',
        description: 'Simulated app manual trigger opened the bin lid.',
        timestamp: DateTime.now(),
        isDemo: true,
      ),
    );

    _addLog(
      'SERVO_ACTUATOR',
      'Simulated servo transition: OPEN completed.',
      LogSeverity.info,
    );
  }

  @override
  Future<void> closeLid() async {
    _addLog(
      'CONTROLS',
      'Simulated command: closeLid() requested.',
      LogSeverity.action,
    );

    _status = _status.copyWith(
      lidState: LidState.moving,
      lastUpdated: DateTime.now(),
    );
    _statusController.add(_status);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _status = _status.copyWith(
      lidState: LidState.closed,
      lastUpdated: DateTime.now(),
    );
    _statusController.add(_status);

    _events.insert(
      0,
      DeviceEvent(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        type: DeviceEventType.lidClosed,
        title: 'Lid Closed (Manual Demo)',
        description: 'Simulated app manual trigger closed the bin lid.',
        timestamp: DateTime.now(),
        isDemo: true,
      ),
    );

    _addLog(
      'SERVO_ACTUATOR',
      'Simulated servo transition: CLOSED completed.',
      LogSeverity.info,
    );
  }

  @override
  Future<void> setOperatingMode(OperatingMode mode) async {
    _addLog(
      'CONTROLS',
      'Simulated command: change mode to ${mode.name}.',
      LogSeverity.action,
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    _status = _status.copyWith(mode: mode, lastUpdated: DateTime.now());
    _statusController.add(_status);

    _events.insert(
      0,
      DeviceEvent(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        type: DeviceEventType.modeChanged,
        title: 'Mode Changed (${mode.name})',
        description: 'Operating mode set to ${mode.displayName}.',
        timestamp: DateTime.now(),
        isDemo: true,
      ),
    );
  }

  @override
  Future<void> setFillPercentage(double? percentage) async {
    _addLog(
      'SIMULATION',
      percentage == null
          ? 'Sensor state set to: UNAVAILABLE (Simulating sensor disconnection).'
          : 'Sensor fill percentage set to: ${percentage.toStringAsFixed(1)}%.',
      percentage == null ? LogSeverity.warning : LogSeverity.info,
    );

    _status = _status.copyWith(
      fillPercentage: () => percentage,
      lastUpdated: DateTime.now(),
    );
    _statusController.add(_status);
  }

  @override
  Future<List<DeviceEvent>> getEvents() async {
    return List.unmodifiable(_events);
  }

  @override
  Future<List<AppAlert>> getAlerts() async {
    return List.unmodifiable(_alerts);
  }

  @override
  Future<void> dismissAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isDismissed: true);
      _addLog('ALERTS', 'Alert $alertId dismissed by user.', LogSeverity.info);
    }
  }

  @override
  Future<List<DebugLogEntry>> getDebugLogs() async {
    return List.unmodifiable(_logs);
  }

  @override
  void clearDebugLogs() {
    _logs.clear();
    _addLog('CORE', 'Debug execution logs cleared by user.', LogSeverity.info);
  }
}
