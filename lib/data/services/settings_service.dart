import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent user settings using `shared_preferences`.
class SettingsService {
  static const String keyEsp32Ip = 'ecobin_esp32_ip';
  static const String keyDemoMode = 'ecobin_demo_mode_enabled';
  static const String keyOnboardingComplete = 'ecobin_onboarding_completed';

  static const String defaultIp = '192.168.4.1';

  /// Validates standard IPv4 address format (e.g., 192.168.4.1).
  static bool isValidIpv4(String ip) {
    final trimmed = ip.trim();
    if (trimmed.isEmpty) return false;

    final parts = trimmed.split('.');
    if (parts.length != 4) {
      return false;
    }

    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      if (part.length > 1 && part.startsWith('0')) {
        return false;
      }
    }
    return true;
  }

  Future<String> getDeviceIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyEsp32Ip) ?? defaultIp;
  }

  Future<void> saveDeviceIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyEsp32Ip, ip.trim());
  }

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyDemoMode) ?? true;
  }

  Future<void> setDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyDemoMode, enabled);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyOnboardingComplete, completed);
  }
}
