// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/errors/device_exceptions.dart';
import '../models/app_alert.dart';
import '../models/debug_log_entry.dart';
import '../models/device_connection_state.dart';
import '../models/device_event.dart';
import '../models/device_status.dart';
import '../services/device_api_service.dart';
import 'device_repository.dart';

/// Real HTTP implementation of [DeviceRepository] communicating directly
/// with the ESP32 microcontroller over the local network.
class HttpDeviceRepository implements DeviceRepository {
  HttpDeviceRepository({
    required DeviceApiService apiService,
    required String deviceIp,
    bool autoStartPolling = true,
  }) : _apiService = apiService,
       _deviceIp = deviceIp {
    _status = DeviceStatus(
      isDemo: false,
      connectionStatus: DeviceConnectionStatus.connecting,
      lidState: LidState.unknown,
      mode: OperatingMode.automatic,
      todayOpenings: 0,
      lastUpdated: DateTime.now(),
      deviceIp: _deviceIp,
      fillPercentage: null, // Starts null (explicitly unavailable until polled)
    );

    if (autoStartPolling) {
      startPolling();
    }
  }

  final DeviceApiService _apiService;
  String _deviceIp;

  late DeviceStatus _status;
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();

  Timer? _pollingTimer;
  bool _isPolling = false;
  int _consecutiveFailures = 0;
  int _currentPollSequence = 0;
  int _lastProcessedSequence = 0;

  final List<DeviceEvent> _events = [];
  final List<AppAlert> _alerts = [];
  final List<DebugLogEntry> _logs = [];

  String get deviceIp => _deviceIp;

  void updateDeviceIp(String newIp) {
    if (_deviceIp != newIp) {
      _deviceIp = newIp.trim();
      _consecutiveFailures = 0;
      _status = _status.copyWith(
        deviceIp: _deviceIp,
        connectionStatus: DeviceConnectionStatus.connecting,
      );
      _statusController.add(_status);
      _addLog(
        '[HTTP_CONFIG]',
        'Target ESP32 IP updated to: $_deviceIp. Triggering reconnect.',
        LogSeverity.info,
      );
      pollStatus();
    }
  }

  void _addLog(String source, String message, LogSeverity severity) {
    if (_logs.length >= AppConstants.maxDebugLogs) {
      _logs.removeLast();
    }
    _logs.insert(
      0,
      DebugLogEntry(
        id: 'log-${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        source: source,
        message: message,
        severity: severity,
        isDemo: false,
      ),
    );
  }

  /// Begins periodic polling with concurrency protection.
  void startPolling() {
    _pollingTimer?.cancel();
    pollStatus(); // Immediate first poll
    _pollingTimer = Timer.periodic(
      AppConstants.statusPollInterval,
      (_) => pollStatus(),
    );
    _addLog(
      '[POLLER]',
      'Periodic status poller started (Interval: ${AppConstants.statusPollInterval.inSeconds}s).',
      LogSeverity.info,
    );
  }

  /// Executes a single status poll with overlapping protection and 3-failure offline threshold.
  Future<void> pollStatus() async {
    if (_isPolling) {
      _addLog(
        '[POLLER]',
        'Skipped poll: previous status request is still in-flight.',
        LogSeverity.info,
      );
      return;
    }

    _isPolling = true;
    final sequence = ++_currentPollSequence;
    final stopwatch = Stopwatch()..start();

    try {
      final fetchedStatus = await _apiService.getStatus(_deviceIp);
      stopwatch.stop();

      // Guard against stale response overwriting newer state
      if (sequence < _lastProcessedSequence) {
        _addLog(
          '[POLLER]',
          'Discarded stale poll response (seq: $sequence < $_lastProcessedSequence).',
          LogSeverity.warning,
        );
        return;
      }
      _lastProcessedSequence = sequence;

      // Reset failure counter on verified response
      final wasOffline =
          _status.connectionStatus == DeviceConnectionStatus.offline;
      _consecutiveFailures = 0;

      _status = fetchedStatus.copyWith(
        connectionStatus: DeviceConnectionStatus.online,
        lastSuccessfulCommunication: DateTime.now(),
        lastUpdated: DateTime.now(),
        deviceIp: _deviceIp,
      );
      _statusController.add(_status);

      _addLog(
        '[HTTP]',
        'GET /api/status -> 200 OK (${stopwatch.elapsedMilliseconds}ms) | Fill: ${_status.fillPercentage?.toStringAsFixed(1) ?? "Null"}%, Lid: ${_status.lidState.name}, Mode: ${_status.mode.name}',
        LogSeverity.info,
      );

      if (wasOffline) {
        _addLog(
          '[CONNECTION]',
          'Connection restored: Device is now ONLINE.',
          LogSeverity.action,
        );
      }
    } on DeviceConnectionException catch (e) {
      stopwatch.stop();
      _consecutiveFailures++;

      _addLog(
        '[HTTP]',
        'GET /api/status FAILED (${stopwatch.elapsedMilliseconds}ms): ${e.message} (Failure $_consecutiveFailures/${AppConstants.maxConsecutivePollFailures})',
        LogSeverity.warning,
      );

      // Transition to offline ONLY after 3 consecutive failures
      if (_consecutiveFailures >= AppConstants.maxConsecutivePollFailures) {
        final transitioned =
            _status.connectionStatus != DeviceConnectionStatus.offline;
        _status = _status.copyWith(
          connectionStatus: DeviceConnectionStatus.offline,
          lastUpdated: DateTime.now(),
        );
        _statusController.add(_status);

        if (transitioned) {
          _addLog(
            '[CONNECTION]',
            'Connection state changed to OFFLINE after $_consecutiveFailures consecutive poll failures.',
            LogSeverity.error,
          );
        }
      }
    } on DeviceDataException catch (e) {
      stopwatch.stop();
      // Parse error: Server responded, but JSON was malformed.
      _addLog(
        '[HTTP_PARSE]',
        'GET /api/status -> Malformed data received (${stopwatch.elapsedMilliseconds}ms): ${e.message}',
        LogSeverity.error,
      );
      // We don't mark as offline since device did respond, but we notify of parse error
    } on DeviceApiException catch (e) {
      stopwatch.stop();
      _consecutiveFailures++;
      _addLog(
        '[HTTP]',
        'GET /api/status -> HTTP ${e.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
        LogSeverity.error,
      );

      if (_consecutiveFailures >= AppConstants.maxConsecutivePollFailures) {
        _status = _status.copyWith(
          connectionStatus: DeviceConnectionStatus.offline,
          lastUpdated: DateTime.now(),
        );
        _statusController.add(_status);
      }
    } catch (e) {
      stopwatch.stop();
      _addLog(
        '[POLLER]',
        'Unexpected polling error (${stopwatch.elapsedMilliseconds}ms): $e',
        LogSeverity.error,
      );
    } finally {
      _isPolling = false;
    }
  }

  @override
  Stream<DeviceStatus> watchStatus() async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  DeviceStatus getCurrentStatus() => _status;

  @override
  Future<void> refreshStatus() async {
    await pollStatus();
  }

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _apiService.checkHealth(_deviceIp);
      stopwatch.stop();

      // Reset failure counter on verified health probe
      _consecutiveFailures = 0;
      _status = _status.copyWith(
        connectionStatus: DeviceConnectionStatus.online,
        lastSuccessfulCommunication: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      _statusController.add(_status);

      _addLog(
        '[HTTP]',
        'GET /api/health -> 200 OK (${stopwatch.elapsedMilliseconds}ms) | Firmware: ${result["firmware"] ?? "unknown"}',
        LogSeverity.info,
      );
      return result;
    } on DeviceConnectionException catch (e) {
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'GET /api/health FAILED (${stopwatch.elapsedMilliseconds}ms): ${e.message}',
        LogSeverity.error,
      );
      rethrow;
    } catch (e) {
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'GET /api/health ERROR (${stopwatch.elapsedMilliseconds}ms): $e',
        LogSeverity.error,
      );
      rethrow;
    }
  }

  @override
  Future<void> openLid() async {
    final stopwatch = Stopwatch()..start();
    _addLog(
      '[CONTROLS]',
      'Dispatching POST /api/lid/open to $_deviceIp',
      LogSeverity.action,
    );

    _status = _status.copyWith(
      lidState: LidState.moving,
      lastUpdated: DateTime.now(),
    );
    _statusController.add(_status);

    try {
      final response = await _apiService.openLid(_deviceIp);
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'POST /api/lid/open -> Accepted (${stopwatch.elapsedMilliseconds}ms)',
        LogSeverity.info,
      );

      // Verify physical movement by polling status after short delay
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await pollStatus();

      _events.insert(
        0,
        DeviceEvent(
          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
          type: DeviceEventType.lidOpened,
          title: 'Lid Open Command',
          description:
              'HTTP command confirmed by device (status: ${response["status"] ?? "accepted"}).',
          timestamp: DateTime.now(),
          isDemo: false,
        ),
      );
    } catch (e) {
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'POST /api/lid/open FAILED (${stopwatch.elapsedMilliseconds}ms): $e',
        LogSeverity.error,
      );
      // Revert moving state
      _status = _status.copyWith(
        lidState: LidState.closed,
        lastUpdated: DateTime.now(),
      );
      _statusController.add(_status);
      rethrow;
    }
  }

  @override
  Future<void> closeLid() async {
    final stopwatch = Stopwatch()..start();
    _addLog(
      '[CONTROLS]',
      'Dispatching POST /api/lid/close to $_deviceIp',
      LogSeverity.action,
    );

    _status = _status.copyWith(
      lidState: LidState.moving,
      lastUpdated: DateTime.now(),
    );
    _statusController.add(_status);

    try {
      final response = await _apiService.closeLid(_deviceIp);
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'POST /api/lid/close -> Accepted (${stopwatch.elapsedMilliseconds}ms)',
        LogSeverity.info,
      );

      await Future<void>.delayed(const Duration(milliseconds: 700));
      await pollStatus();

      _events.insert(
        0,
        DeviceEvent(
          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
          type: DeviceEventType.lidClosed,
          title: 'Lid Close Command',
          description:
              'HTTP command confirmed by device (status: ${response["status"] ?? "accepted"}).',
          timestamp: DateTime.now(),
          isDemo: false,
        ),
      );
    } catch (e) {
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'POST /api/lid/close FAILED (${stopwatch.elapsedMilliseconds}ms): $e',
        LogSeverity.error,
      );
      _status = _status.copyWith(
        lidState: LidState.open,
        lastUpdated: DateTime.now(),
      );
      _statusController.add(_status);
      rethrow;
    }
  }

  @override
  Future<void> setOperatingMode(OperatingMode mode) async {
    final stopwatch = Stopwatch()..start();
    _addLog(
      '[CONTROLS]',
      'Dispatching POST /api/mode with mode="${mode.name}" to $_deviceIp',
      LogSeverity.action,
    );

    try {
      await _apiService.setMode(_deviceIp, mode);
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'POST /api/mode -> 200 OK (${stopwatch.elapsedMilliseconds}ms)',
        LogSeverity.info,
      );

      _status = _status.copyWith(mode: mode, lastUpdated: DateTime.now());
      _statusController.add(_status);

      _events.insert(
        0,
        DeviceEvent(
          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
          type: DeviceEventType.modeChanged,
          title: 'Operating Mode Updated',
          description: 'Mode set to ${mode.displayName} via HTTP.',
          timestamp: DateTime.now(),
          isDemo: false,
        ),
      );
    } catch (e) {
      stopwatch.stop();
      _addLog(
        '[HTTP]',
        'POST /api/mode FAILED (${stopwatch.elapsedMilliseconds}ms): $e',
        LogSeverity.error,
      );
      rethrow;
    }
  }

  @override
  Future<void> setFillPercentage(double? percentage) async {
    // In real mode, fill level is reported by hardware sensor, not set arbitrarily
    _addLog(
      '[WARNING]',
      'Manual fill level override is ignored in Real HTTP mode.',
      LogSeverity.warning,
    );
  }

  @override
  Future<List<DeviceEvent>> getEvents() async {
    return List.unmodifiable(_events);
  }

  @override
  Future<List<AppAlert>> getAlerts() async {
    final list = List<AppAlert>.from(_alerts);
    if (_status.connectionStatus == DeviceConnectionStatus.offline) {
      list.insert(
        0,
        AppAlert(
          id: 'alert-offline',
          title: 'ESP32 Device Offline',
          message:
              'No response from $_deviceIp after multiple attempts. Check power and WiFi connection.',
          severity: AlertSeverity.critical,
          timestamp: DateTime.now(),
          isDemo: false,
        ),
      );
    }
    return List.unmodifiable(list);
  }

  @override
  Future<void> dismissAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isDismissed: true);
    }
  }

  @override
  Future<List<DebugLogEntry>> getDebugLogs() async {
    return List.unmodifiable(_logs);
  }

  @override
  void clearDebugLogs() {
    _logs.clear();
    _addLog('[CORE]', 'HTTP diagnostics trace cleared.', LogSeverity.info);
  }

  @override
  void pausePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _addLog(
      '[POLLER]',
      'Status poller PAUSED (App in background).',
      LogSeverity.info,
    );
  }

  @override
  void resumePolling() {
    _addLog(
      '[POLLER]',
      'Status poller RESUMED (App in foreground).',
      LogSeverity.info,
    );
    startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _statusController.close();
    _apiService.dispose();
  }
}
