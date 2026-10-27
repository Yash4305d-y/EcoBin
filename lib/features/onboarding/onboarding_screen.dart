import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/services/settings_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _ipController;
  String? _ipError;

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

  Future<void> _handleContinueDemo() async {
    await ref.read(settingsProvider.notifier).setDemoMode(true);
    await ref.read(settingsProvider.notifier).completeOnboarding();
    widget.onFinished();
  }

  Future<void> _handleSaveAndContinue() async {
    final ip = _ipController.text.trim();
    if (!SettingsService.isValidIpv4(ip)) {
      setState(() {
        _ipError = 'Please enter a valid IPv4 address (e.g. 192.168.4.1)';
      });
      return;
    }

    setState(() => _ipError = null);
    await ref.read(settingsProvider.notifier).updateDeviceIp(ip);
    await ref.read(settingsProvider.notifier).completeOnboarding();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.gapH24,

              // App Hero Branding
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreenContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mintGreen, width: 2),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: AppColors.mintGreen,
                    size: 44,
                  ),
                ),
              ),
              AppSpacing.gapH16,

              const Text(
                'Welcome to EcoBin',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH8,
              const Text(
                'Smart contactless waste monitoring and lid actuation for ESP32-based IoT bins.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH32,

              // Highlights List
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurface,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: const Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.sensors_rounded,
                      title: 'Ultrasonic Telemetry',
                      subtitle: 'Accurate continuous bin fill-level sensing.',
                    ),
                    Divider(height: AppSpacing.xl),
                    _FeatureRow(
                      icon: Icons.touch_app_rounded,
                      title: 'Dual Operating Modes',
                      subtitle: 'Switch between Automatic trigger and Manual locking.',
                    ),
                    Divider(height: AppSpacing.xl),
                    _FeatureRow(
                      icon: Icons.shield_outlined,
                      title: 'Local Privacy First',
                      subtitle: 'Direct local WiFi communication with no third-party cloud required.',
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,

              // Hardware Setup Card
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurfaceCard,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESP32 Device Configuration',
                      style: AppTextStyles.titleSmall,
                    ),
                    AppSpacing.gapH4,
                    const Text(
                      'If you have your ESP32 connected, specify its local IP. You can also explore all features without hardware in Demo Mode.',
                      style: AppTextStyles.bodySmall,
                    ),
                    AppSpacing.gapH12,
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'ESP32 Local IP Address',
                        hintText: '192.168.4.1',
                        prefixIcon: const Icon(Icons.wifi_rounded, size: 20),
                        errorText: _ipError,
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,

              // Action Buttons
              FilledButton.icon(
                onPressed: _handleContinueDemo,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Launch Demo Mode (No Hardware)'),
              ),
              AppSpacing.gapH12,
              OutlinedButton.icon(
                onPressed: _handleSaveAndContinue,
                icon: const Icon(Icons.settings_ethernet_rounded),
                label: const Text('Save IP & Enter App'),
              ),
              AppSpacing.gapH16,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.slateSurfaceVariant,
            borderRadius: AppRadii.borderRadiusSm,
          ),
          child: Icon(icon, color: AppColors.mintGreen, size: 20),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall),
              AppSpacing.gapH4,
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
