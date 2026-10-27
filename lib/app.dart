import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/settings_provider.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'navigation/app_nav_shell.dart';

/// Root application widget for EcoBin.
class EcoBinApp extends ConsumerWidget {
  const EcoBinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'EcoBin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: !settings.isLoaded
          ? const Scaffold(
              backgroundColor: AppColors.darkNavy,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.mintGreen),
              ),
            )
          : !settings.isOnboardingCompleted
          ? OnboardingScreen(
              onFinished: () {
                // Handled internally in OnboardingScreen through settingsProvider
              },
            )
          : const AppNavShell(),
    );
  }
}
