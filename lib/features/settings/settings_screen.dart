import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/demo_badge.dart';
import '../../data/providers/device_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/services/settings_service.dart';

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
          content: Text(
            'Saved ESP32 IP: $ip (Persisted via SharedPreferences)',
          ),
          backgroundColor: AppColors.successContainer,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleTestConnection() async {
    final settings = ref.read(settingsProvider);
    final isDemo = settings.isDemoMode;
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
                'Probing GET /api/health...',
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
                isDemo
                    ? 'Simulated health check completed successfully.'
                    : 'Real HTTP handshake confirmed with ESP32 at $ip.',
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
              Text('Error: $e', style: AppTextStyles.bodySmall),
              AppSpacing.gapH8,
              const Text(
                'Troubleshooting:\n• Ensure ESP32 is powered via 5V.\n• Verify your phone is connected to the same WiFi / SoftAP.\n• Confirm device IP matches your router DHCP table.',
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
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Device Settings & Configuration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Demo Mode Switch Card
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurface,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(
                    color: settings.isDemoMode
                        ? AppColors.warning.withValues(alpha: 0.4)
                        : AppColors.slateOutlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          color: AppColors.warning,
                          size: 22,
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Demo Mode (Simulated)',
                                style: AppTextStyles.titleSmall,
                              ),
                              Text(
                                'Simulate telemetry & hardware responses',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.isDemoMode,
                          activeThumbColor: AppColors.mintGreen,
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .setDemoMode(val);
                          },
                        ),
                      ],
                    ),
                    if (settings.isDemoMode) ...[
                      AppSpacing.gapH8,
                      const DemoBanner(
                        message: 'Demo Mode is active. Readings, actuation, and events are mocked for safe testing.',
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapH20,

              // ESP32 IP Configuration Card
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurface,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESP32 Device IP Address',
                      style: AppTextStyles.titleSmall,
                    ),
                    AppSpacing.gapH4,
                    const Text(
                      'Stored locally in SharedPreferences. Used for future Phase 3 local HTTP telemetry calls.',
                      style: AppTextStyles.bodySmall,
                    ),
                    AppSpacing.gapH12,
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'Local Network IP Address',
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
                          child: FilledButton.icon(
                            onPressed: _handleSaveIp,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save IP'),
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleTestConnection,
                            icon: const Icon(Icons.network_check_rounded),
                            label: const Text('Test Connection'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH20,

              // Diagnostics & Debug Logs Navigation
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurface,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnostics & Debug Logs',
                      style: AppTextStyles.titleSmall,
                    ),
                    AppSpacing.gapH4,
                    const Text(
                      'Inspect real-time command dispatch, actuation state events, and simulated telemetry logs.',
                      style: AppTextStyles.bodySmall,
                    ),
                    AppSpacing.gapH12,
                    OutlinedButton.icon(
                      onPressed: widget.onOpenDebugLogs,
                      icon: const Icon(Icons.terminal_rounded),
                      label: const Text('Open Debug Logs Viewer'),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH20,

              // Connection Troubleshooting Guide
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurfaceCard,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.mintGreen,
                          size: 20,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'ESP32 Setup & Troubleshooting',
                          style: AppTextStyles.titleSmall,
                        ),
                      ],
                    ),
                    AppSpacing.gapH12,
                    _TroubleshootStep(
                      step: '1',
                      title: 'Power & Firmware',
                      description: 'Connect ESP32 via 5V 2A microUSB/Type-C. Ensure firmware is running and servo leads are connected to GPIO 18.',
                    ),
                    _TroubleshootStep(
                      step: '2',
                      title: 'SoftAP vs Station Mode',
                      description: 'In SoftAP mode, connect phone to "EcoBin-AP" (IP 192.168.4.1). In Station mode, configure phone on the same 2.4GHz WiFi network.',
                    ),
                    _TroubleshootStep(
                      step: '3',
                      title: 'Cleartext HTTP Rule',
                      description: 'Local ESP32 web servers do not use TLS certificates. Cleartext local traffic is explicitly permitted for local private IP subnets.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TroubleshootStep extends StatelessWidget {
  const _TroubleshootStep({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.slateSurfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.mintGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
