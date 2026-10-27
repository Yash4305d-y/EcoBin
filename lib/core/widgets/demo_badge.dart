import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Compact badge indicating that the surrounding data is simulated.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, this.text = 'DEMO DATA'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningContainer.withValues(alpha: 0.5),
        borderRadius: AppRadii.borderRadiusXs,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.science_outlined,
            size: 12,
            color: AppColors.onWarningContainer,
          ),
          AppSpacing.gapW4,
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onWarningContainer,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width contextual banner visibly signaling that all readings
/// and interactions on the screen are simulated.
class DemoBanner extends StatelessWidget {
  const DemoBanner({
    super.key,
    this.message = 'Demo Mode Active: All sensor readings and hardware actions are simulated.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.slateSurfaceCard,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
