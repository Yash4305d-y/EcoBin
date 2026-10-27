import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_alert.dart';
import '../models/debug_log_entry.dart';
import '../models/device_event.dart';
import '../models/device_status.dart';
import '../repositories/device_repository.dart';
import '../repositories/http_device_repository.dart';
import '../repositories/mock_device_repository.dart';
import '../services/device_api_service.dart';
import 'settings_provider.dart';

/// Provides the low-level HTTP API client.
final deviceApiServiceProvider = Provider<DeviceApiService>((ref) {
  final service = DeviceApiService();
  ref.onDispose(service.dispose);
  return service;
});

/// Dedicated in-memory mock repository for Demo Mode.
final mockDeviceRepositoryProvider = Provider<MockDeviceRepository>((ref) {
  final repo = MockDeviceRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Dedicated real HTTP repository targeting physical ESP32 endpoints.
final httpDeviceRepositoryProvider = Provider<HttpDeviceRepository>((ref) {
  final apiService = ref.watch(deviceApiServiceProvider);
  final settings = ref.watch(settingsProvider);

  final repo = HttpDeviceRepository(
    apiService: apiService,
    deviceIp: settings.deviceIp,
    autoStartPolling: !settings.isDemoMode,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Dynamically selects the active [DeviceRepository] based on Demo Mode setting.
///
/// Guaranteed separation:
/// - In Demo Mode: returns [MockDeviceRepository]
/// - In Real Mode: returns [HttpDeviceRepository] with zero simulated telemetry leakage.
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final settings = ref.watch(settingsProvider);

  if (settings.isDemoMode) {
    return ref.watch(mockDeviceRepositoryProvider);
  } else {
    final httpRepo = ref.watch(httpDeviceRepositoryProvider);
    httpRepo.updateDeviceIp(settings.deviceIp);
    return httpRepo;
  }
});

/// Streams real-time / polled updates of the [DeviceStatus].
final deviceStatusProvider = StreamProvider<DeviceStatus>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.watchStatus();
});

/// Manages whether a hardware command is currently executing.
/// Used to disable conflicting actions in the UI.
class CommandPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setPending(bool value) {
    state = value;
  }
}

final isCommandPendingProvider = NotifierProvider<CommandPendingNotifier, bool>(
  CommandPendingNotifier.new,
);

/// Provides the list of recent device activity events.
final deviceEventsProvider = FutureProvider<List<DeviceEvent>>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.getEvents();
});

/// Provides active in-app alerts.
final alertsProvider = FutureProvider<List<AppAlert>>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.getAlerts();
});

/// Provides runtime execution debug logs.
final debugLogsProvider = FutureProvider<List<DebugLogEntry>>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.getDebugLogs();
});
