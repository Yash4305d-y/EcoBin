import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_radii.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';

/// Root application widget for EcoBin.
class EcoBinApp extends StatelessWidget {
  const EcoBinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoBin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const FoundationScreen(),
    );
  }
}

/// Minimal, polished shell screen verifying project foundation,
/// Material 3 theme tokens, and Riverpod integration.
class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.mintGreenContainer,
                borderRadius: AppRadii.borderRadiusSm,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.mintGreen,
                size: 20,
              ),
            ),
            AppSpacing.gapW8,
            const Text('EcoBin'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foundation Status Card
              Card(
                child: Padding(
                  padding: AppSpacing.paddingCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintGreenContainer,
                              borderRadius: AppRadii.borderRadiusXs,
                            ),
                            child: Text(
                              'PHASE 1 READY',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.onMintGreenContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.mintGreen,
                            size: 20,
                          ),
                        ],
                      ),
                      AppSpacing.gapH12,
                      const Text(
                        'Project Foundation & Shell',
                        style: AppTextStyles.titleLarge,
                      ),
                      AppSpacing.gapH8,
                      const Text(
                        'The EcoBin project baseline has been successfully initialized. Core design tokens, Riverpod state container, and Android target configurations are active.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapH16,

              // Architecture Checklist
              const Text(
                'Baseline Specifications',
                style: AppTextStyles.titleMedium,
              ),
              AppSpacing.gapH12,

              const _FoundationSpecItem(
                icon: Icons.palette_outlined,
                title: 'Design Tokens',
                description: 'Dark navy (#0A0F1D), mint green accent (#00E599), and slate surfaces configured in Material 3.',
              ),
              AppSpacing.gapH8,

              const _FoundationSpecItem(
                icon: Icons.layers_outlined,
                title: 'State Management',
                description: 'Root wrapped in Riverpod ProviderScope for reactive state handling.',
              ),
              AppSpacing.gapH8,

              const _FoundationSpecItem(
                icon: Icons.android_outlined,
                title: 'Android Target & Permissions',
                description: 'Minimum SDK 23, portrait-only orientation, and network permissions prepared for local ESP32 HTTP.',
              ),
              AppSpacing.gapH8,

              const _FoundationSpecItem(
                icon: Icons.inventory_2_outlined,
                title: 'Agreed Dependencies',
                description: 'flutter_riverpod, http, shared_preferences, sqflite, and fl_chart registered.',
              ),
              AppSpacing.gapH24,

              // Next Phase Notice
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.slateSurfaceCard,
                  borderRadius: AppRadii.borderRadiusLg,
                  border: Border.all(color: AppColors.slateOutlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.info,
                      size: 24,
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phase 2 Next Steps',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          AppSpacing.gapH4,
                          const Text(
                            'ESP32 discovery, onboarding flow, and live bin telemetry dashboard.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
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

class _FoundationSpecItem extends StatelessWidget {
  const _FoundationSpecItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.slateSurface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.slateOutlineVariant),
      ),
      child: Row(
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
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
