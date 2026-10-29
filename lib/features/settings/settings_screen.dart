import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../data/providers/demo_mode_provider.dart';
import '../../data/providers/device_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/services/settings_service.dart';
import '../dashboard/widgets/fill_demo_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.onOpenDebugLogs});

  final VoidCallback onOpenDebugLogs;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _ipController;
  String? _ipError;
  bool _savedFeedback = false;

  @override
  void initState() {
    super.initState();
    final currentIp = ref.read(settingsProvider).deviceIp;
    _ipController = TextEditingController(text: currentIp);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveIp() async {
    final ip = _ipController.text.trim();
    if (!SettingsService.isValidIpv4(ip)) {
      setState(() {
        _ipError = 'Please enter a valid IPv4 address (e.g. 192.168.4.1)';
        _savedFeedback = false;
      });
      return;
    }

    setState(() {
      _ipError = null;
      _savedFeedback = true;
    });

    await ref.read(settingsProvider.notifier).updateDeviceIp(ip);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ESP32 IP: $ip'),
          backgroundColor: AppColors.successContainer,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleTestConnection() async {
    final settings = ref.read(settingsProvider);
    final ip = settings.deviceIp;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: AppColors.slateSurface,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.mintGreen),
            AppSpacing.gapW16,
            Expanded(
              child: Text(
                'Connecting to EcoBin...',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final repo = ref.read(deviceRepositoryProvider);
      final result = await repo.checkHealth();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.slateSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderRadiusLg,
            side: const BorderSide(color: AppColors.mintGreen),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.mintGreen),
              AppSpacing.gapW8,
              Text('Connection Verified', style: AppTextStyles.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected to EcoBin at $ip.',
                style: AppTextStyles.bodyMedium,
              ),
              AppSpacing.gapH8,
              Text(
                'Device: ${result["device"] ?? "ecobin-esp32"}',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                'Firmware: ${result["firmware"] ?? "1.0.0"}',
                style: AppTextStyles.bodySmall,
              ),
              if (result["uptime_seconds"] != null)
                Text(
                  'Uptime: ${result["uptime_seconds"]}s',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.slateSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderRadiusLg,
            side: const BorderSide(color: AppColors.error),
          ),
          title: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: AppColors.error),
              AppSpacing.gapW8,
              Text('Connection Failed', style: AppTextStyles.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not reach ESP32 at http://$ip',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              AppSpacing.gapH8,
              const Text(
                'Check that EcoBin is powered on and connected to the same local Wi-Fi.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Settings & Configuration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreenWithNav,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ESP32 IP Configuration Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESP32 Device IP Address',
                      style: AppTextStyles.titleSmall,
                    ),
                    AppSpacing.gapH12,
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'IP Address',
                        hintText: '192.168.4.1',
                        prefixIcon: const Icon(Icons.settings_ethernet_rounded),
                        errorText: _ipError,
                        suffixIcon: _savedFeedback
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.mintGreen,
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    AppSpacing.gapH16,
                    Row(
                      children: [
                        Expanded(
                          child: PressableScale(
                            onTap: _handleSaveIp,
                            child: FilledButton.icon(
                              onPressed: _handleSaveIp,
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Save IP'),
                            ),
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: PressableScale(
                            onTap: _handleTestConnection,
                            child: OutlinedButton.icon(
                              onPressed: _handleTestConnection,
                              icon: const Icon(
                                Icons.network_check_rounded,
                                size: 18,
                              ),
                              label: const Text('Test Connection'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,

              // Diagnostics & Debug Logs Navigation Tile
              AppCard(
                padding: EdgeInsets.zero,
                child: PressableScale(
                  onTap: widget.onOpenDebugLogs,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen.withValues(alpha: 0.12),
                            borderRadius: AppRadii.borderRadiusSm,
                          ),
                          child: const Icon(
                            Icons.terminal_rounded,
                            color: AppColors.mintGreen,
                            size: 18,
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Diagnostics & Debug Logs',
                                style: AppTextStyles.titleSmall,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Real-time telemetry and network transactions',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!kReleaseMode) ...[
                AppSpacing.gapH16,
                // Developer Preview Demo Mode Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.science_outlined,
                                size: 18,
                                color: AppColors.warning,
                              ),
                              AppSpacing.gapW8,
                              Text(
                                'Fill Level Demo Preview',
                                style: AppTextStyles.titleSmall,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: AppRadii.borderRadiusXs,
                            ),
                            child: const Text(
                              'DEBUG ONLY',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      Text(
                        'Temporarily simulate dustbin fill levels to preview gauge animations and threshold colors. Connection status remains genuinely Offline.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapH12,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => showFillDemoSheet(context),
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: Text(
                                ref.watch(isFillDemoActiveProvider)
                                    ? 'Adjust Demo (${ref.watch(fillDemoOverrideProvider)?.toInt()}%)'
                                    : 'Open Demo Controls',
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: ref.watch(isFillDemoActiveProvider)
                                      ? AppColors.warning
                                      : AppColors.slateOutlineVariant,
                                ),
                              ),
                            ),
                          ),
                          if (ref.watch(isFillDemoActiveProvider)) ...[
                            AppSpacing.gapW8,
                            IconButton(
                              tooltip: 'Turn Off Demo Mode',
                              icon: const Icon(
                                Icons.power_settings_new_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => ref
                                  .read(fillDemoOverrideProvider.notifier)
                                  .disable(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
