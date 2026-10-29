import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pressable_scale.dart';
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
    await ref.read(settingsProvider.notifier).setDemoMode(false);
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
              AppSpacing.gapH32,

              // App Hero Branding
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreenContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mintGreen.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mintGreen.withValues(alpha: 0.12),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: AppColors.mintGreen,
                    size: 38,
                  ),
                ),
              ),
              AppSpacing.gapH20,

              const Text(
                'Welcome to EcoBin',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH8,
              Text(
                'Smart contactless waste monitoring and actuation companion.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH32,

              // Device IP Connection Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect to EcoBin',
                      style: AppTextStyles.titleSmall,
                    ),
                    AppSpacing.gapH4,
                    Text(
                      'Enter your ESP32 device IP address to connect on your local network.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapH16,
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'ESP32 IP Address',
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

              // Connect Action Button
              PressableScale(
                onTap: _handleSaveAndContinue,
                child: FilledButton.icon(
                  onPressed: _handleSaveAndContinue,
                  icon: const Icon(Icons.wifi_rounded, size: 18),
                  label: const Text('Connect to EcoBin'),
                ),
              ),
              AppSpacing.gapH16,
            ],
          ),
        ),
      ),
    );
  }
}
