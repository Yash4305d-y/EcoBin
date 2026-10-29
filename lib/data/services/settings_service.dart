import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent user settings using `shared_preferences`.
class SettingsService {
  static const String keyEsp32Ip = 'ecobin_esp32_ip';
  static const String keyDemoMode = 'ecobin_demo_mode_enabled';
  static const String keyOnboardingComplete = 'ecobin_onboarding_completed';

  static const String defaultIp = '10.236.242.197';

  /// Sanitizes user-entered IP strings by stripping URI schemes, paths, and ports.
  static String sanitizeIp(String input) {
    var clean = input.trim();
    if (clean.startsWith('http://')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('https://')) {
      clean = clean.substring(8);
    }
    final slashIdx = clean.indexOf('/');
    if (slashIdx != -1) {
      clean = clean.substring(0, slashIdx);
    }
    final colonIdx = clean.indexOf(':');
    if (colonIdx != -1) {
      clean = clean.substring(0, colonIdx);
    }
    return clean.trim();
  }

  /// Validates standard IPv4 address format (e.g., 10.236.242.197).
  static bool isValidIpv4(String ip) {
    final clean = sanitizeIp(ip);
    if (clean.isEmpty) return false;

    final parts = clean.split('.');
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
    final saved = prefs.getString(keyEsp32Ip);
    if (saved == null || saved.trim() == '192.168.4.1') {
      await prefs.setString(keyEsp32Ip, defaultIp);
      return defaultIp;
    }
    return sanitizeIp(saved);
  }

  Future<void> saveDeviceIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyEsp32Ip, sanitizeIp(ip));
  }

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyDemoMode) ?? false;
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
