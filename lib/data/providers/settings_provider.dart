import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

class SettingsState {
  const SettingsState({
    required this.deviceIp,
    required this.isDemoMode,
    required this.isOnboardingCompleted,
    required this.isLoaded,
  });

  factory SettingsState.initial() => const SettingsState(
    deviceIp: SettingsService.defaultIp,
    isDemoMode: false,
    isOnboardingCompleted: false,
    isLoaded: false,
  );

  final String deviceIp;
  final bool isDemoMode;
  final bool isOnboardingCompleted;
  final bool isLoaded;

  SettingsState copyWith({
    String? deviceIp,
    bool? isDemoMode,
    bool? isOnboardingCompleted,
    bool? isLoaded,
  }) {
    return SettingsState(
      deviceIp: deviceIp ?? this.deviceIp,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState.initial();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(settingsServiceProvider);
    final ip = await service.getDeviceIp();
    final demo = await service.isDemoMode();
    final onboarding = await service.isOnboardingCompleted();

    if (!ref.mounted) return;
    state = state.copyWith(
      deviceIp: ip,
      isDemoMode: demo,
      isOnboardingCompleted: onboarding,
      isLoaded: true,
    );
  }

  Future<void> updateDeviceIp(String newIp) async {
    await ref.read(settingsServiceProvider).saveDeviceIp(newIp);
    state = state.copyWith(deviceIp: newIp.trim());
  }

  Future<void> setDemoMode(bool enabled) async {
    await ref.read(settingsServiceProvider).setDemoMode(enabled);
    state = state.copyWith(isDemoMode: enabled);
  }

  Future<void> completeOnboarding() async {
    await ref.read(settingsServiceProvider).setOnboardingCompleted(true);
    state = state.copyWith(isOnboardingCompleted: true);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
