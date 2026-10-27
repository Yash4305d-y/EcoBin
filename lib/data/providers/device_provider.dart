import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_alert.dart';
import '../models/debug_log_entry.dart';
import '../models/device_event.dart';
import '../models/device_status.dart';
import '../repositories/device_repository.dart';
import '../repositories/mock_device_repository.dart';

/// Provides the active [DeviceRepository] implementation.
/// Currently defaults to [MockDeviceRepository] in Phase 2.
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return MockDeviceRepository();
});

/// Streams real-time / simulated updates of the [DeviceStatus].
final deviceStatusProvider = StreamProvider<DeviceStatus>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.watchStatus();
});

/// Manages whether a hardware or simulated command is currently executing.
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
