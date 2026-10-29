import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Reusable status chip featuring smooth animated state, icon, and color transitions.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.accentColor = AppColors.mintGreen,
    this.backgroundColor,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.fast);
    final bg = backgroundColor ?? AppColors.surfaceNearBlack;

    final content = AnimatedContainer(
      duration: duration,
      curve: AppMotion.smoothCurve,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.borderRadiusFull,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: duration,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Icon(
              icon,
              key: ValueKey<IconData>(icon),
              size: 13,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 5),
          AnimatedDefaultTextStyle(
            duration: duration,
            curve: AppMotion.smoothCurve,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
            child: Text(label),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderRadiusFull,
        child: content,
      );
    }

    return content;
  }
}
