import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages temporary, developer-only fill level simulation for UI previewing.
///
/// Strictly in-memory and automatically disabled in release mode (`kReleaseMode`).
/// Does NOT persist to storage or simulate fake hardware connection states.
class FillDemoNotifier extends Notifier<double?> {
  @override
  double? build() {
    // Strictly disabled in production/release builds
    if (kReleaseMode) return null;
    return null; // Default is null (disabled, real sensor/offline state)
  }

  /// Sets the simulated fill level clamped between 0.0% and 100.0%.
  void setFillPercentage(double percentage) {
    if (kReleaseMode) return;
    state = percentage.clamp(0.0, 100.0);
  }

  /// Disables demo mode, returning to authentic sensor data / offline state.
  void disable() {
    state = null;
  }
}

/// Provides the current simulated fill percentage, or `null` if demo mode is off.
final fillDemoOverrideProvider = NotifierProvider<FillDemoNotifier, double?>(
  FillDemoNotifier.new,
);

/// Boolean helper to check if fill demo mode is actively running.
final isFillDemoActiveProvider = Provider<bool>((ref) {
  if (kReleaseMode) return false;
  return ref.watch(fillDemoOverrideProvider) != null;
});
