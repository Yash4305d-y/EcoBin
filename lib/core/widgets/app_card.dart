import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Minimalist elevated container for EcoBin.
///
/// Features:
/// - Near-black surface (#101313) used sparingly for clear visual hierarchy
/// - Restrained 1px border with subtle dark gray (#1E2424)
/// - Soft top highlight without heavy shadows or glow
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
        borderColor ?? AppColors.slateOutlineVariant.withValues(alpha: 0.8);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (gradient == null ? AppColors.surfaceNearBlack : null),
        gradient:
            gradient ??
            (backgroundColor == null ? AppColors.cardGradient : null),
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0AFFFFFF),
            offset: Offset(0, 1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
