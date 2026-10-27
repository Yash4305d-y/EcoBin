import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Animated radial fill gauge for the EcoBin companion app.
///
/// Follows strict threshold coloring:
/// - Green (< 50%)
/// - Yellow/Amber (50% - 80%)
/// - Red (> 80%)
///
/// If [fillPercentage] is null, explicitly displays an "Unavailable" state
/// without falsifying a 0% reading.
class AnimatedFillGauge extends StatelessWidget {
  const AnimatedFillGauge({
    super.key,
    required this.fillPercentage,
    this.isDemo = true,
    this.size = 180.0,
    this.strokeWidth = 14.0,
  });

  /// Value from 0.0 to 100.0, or null if sensor is unavailable.
  final double? fillPercentage;
  final bool isDemo;
  final double size;
  final double strokeWidth;

  Color _getThresholdColor(double percentage) {
    if (percentage < 50.0) {
      return AppColors.mintGreen;
    } else if (percentage <= 80.0) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _getThresholdLabel(double percentage) {
    if (percentage < 50.0) {
      return 'Low Capacity';
    } else if (percentage <= 80.0) {
      return 'Moderate Fill';
    } else {
      return 'Nearly Full / Action Needed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnavailable = fillPercentage == null;

    if (isUnavailable) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: strokeWidth,
                color: AppColors.slateOutlineVariant,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sensors_off_rounded,
                  size: 32,
                  color: AppColors.textTertiary,
                ),
                AppSpacing.gapH4,
                const Text('— %', style: AppTextStyles.headlineMedium),
                AppSpacing.gapH4,
                Text(
                  'Sensor Offline',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (isDemo) ...[
                  const SizedBox(height: 2),
                  Text(
                    '(Simulated State)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    final percentage = fillPercentage!.clamp(0.0, 100.0);
    final targetColor = _getThresholdColor(percentage);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: percentage),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  color: AppColors.slateSurfaceVariant,
                ),
              ),
              // Dynamic filled track
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: animatedValue / 100.0,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: targetColor,
                ),
              ),
              // Center readout
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${animatedValue.toStringAsFixed(0)}%',
                    style: AppTextStyles.displaySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getThresholdLabel(animatedValue),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: targetColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isDemo) ...[
                    AppSpacing.gapH4,
                    Text(
                      'Demo Reading',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
