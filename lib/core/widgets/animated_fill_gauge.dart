import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Animated radial fill gauge for the EcoBin companion app.
///
/// Follows strict threshold coloring:
/// - Mint Green & Teal accent (< 50%)
/// - Warning Amber (50% - 80%)
/// - Error Red (> 80%)
///
/// If [fillPercentage] is null, explicitly displays an "Unavailable" state
/// without falsifying a 0% reading.
///
/// Animates smoothly between actual fill values over [AppMotion.gaugeFill],
/// blurs a low-opacity accent glow behind the dial, and respects system
/// accessibility reduced-motion settings.
class AnimatedFillGauge extends StatefulWidget {
  const AnimatedFillGauge({
    super.key,
    required this.fillPercentage,
    this.size = 185.0,
    this.strokeWidth = 12.0,
  });

  /// Value from 0.0 to 100.0, or null if sensor reading is unavailable.
  final double? fillPercentage;
  final double size;
  final double strokeWidth;

  @override
  State<AnimatedFillGauge> createState() => _AnimatedFillGaugeState();
}

class _AnimatedFillGaugeState extends State<AnimatedFillGauge> {
  double _previousPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.fillPercentage != null) {
      _previousPercentage = widget.fillPercentage!.clamp(0.0, 100.0);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedFillGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillPercentage != null && widget.fillPercentage != null) {
      // Only update previous percentage if the value meaningfully changed (> 0.05)
      if ((oldWidget.fillPercentage! - widget.fillPercentage!).abs() > 0.05) {
        _previousPercentage = oldWidget.fillPercentage!.clamp(0.0, 100.0);
      }
    } else if (widget.fillPercentage != null) {
      _previousPercentage = widget.fillPercentage!.clamp(0.0, 100.0);
    }
  }

  Color _getBlendedColor(double percentage) {
    if (percentage < 50.0) {
      final t = (percentage / 50.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF00C9A7), AppColors.mintGreen, t)!;
    } else if (percentage <= 80.0) {
      final t = ((percentage - 50.0) / 30.0).clamp(0.0, 1.0);
      return Color.lerp(AppColors.mintGreen, AppColors.warning, t)!;
    } else {
      final t = ((percentage - 80.0) / 20.0).clamp(0.0, 1.0);
      return Color.lerp(AppColors.warning, AppColors.error, t)!;
    }
  }

  String _getThresholdLabel(double percentage) {
    if (percentage < 50.0) {
      return 'Low Capacity';
    } else if (percentage <= 80.0) {
      return 'Moderate Fill';
    } else {
      return 'Nearly Full';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnavailable = widget.fillPercentage == null;

    if (isUnavailable) {
      return RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: widget.strokeWidth,
                  color: AppColors.slateOutlineVariant.withValues(alpha: 0.6),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sensors_off_rounded,
                    size: 28,
                    color: AppColors.textTertiary,
                  ),
                  AppSpacing.gapH4,
                  Text(
                    'Unavailable',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fill Sensor Offline',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final targetPercentage = widget.fillPercentage!.clamp(0.0, 100.0);
    final animationDuration = AppMotion.duration(context, AppMotion.gaugeFill);

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: _previousPercentage, end: targetPercentage),
        duration: animationDuration,
        curve: AppMotion.enterCurve,
        builder: (context, animatedValue, child) {
          final currentColor = _getBlendedColor(animatedValue);

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle ambient glow behind gauge
                Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withValues(alpha: 0.08),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Subtle background track
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: widget.strokeWidth,
                    color: AppColors.slateSurfaceVariant,
                  ),
                ),
                // Dynamic filled track
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    value: animatedValue / 100.0,
                    strokeWidth: widget.strokeWidth,
                    strokeCap: StrokeCap.round,
                    color: currentColor,
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
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getThresholdLabel(animatedValue),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: currentColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
