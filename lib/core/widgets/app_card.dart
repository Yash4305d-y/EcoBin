import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Minimalist elevated container for EcoBin.
///
/// Features:
/// - Subtle directional surface gradient
/// - Restrained 1px border with soft opacity
/// - Soft top highlight for consumer hardware depth
/// - Clean background canvas integration without heavy shadows
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.gradient,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadii.borderRadiusLg;
    final effectiveBorderColor =
        borderColor ?? AppColors.slateOutlineVariant.withValues(alpha: 0.6);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (gradient == null ? AppColors.slateSurface : null),
        gradient:
            gradient ??
            (backgroundColor == null ? AppColors.cardGradient : null),
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorderColor, width: 1),
        boxShadow: [
          // Soft top highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.02),
            offset: const Offset(0, 1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
          // Subtle resting depth
          BoxShadow(
            color: AppColors.darkNavyDeep.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}
