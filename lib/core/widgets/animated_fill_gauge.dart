import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Animated radial fill gauge for the EcoBin companion app.
///
/// Follows strict threshold coloring:
/// - Mint Green (< 50%)
/// - Warning Yellow (50% - 80%)
/// - Error Red (> 80%)
///
/// Features:
/// - Smooth spring animation with controlled transition on updates.
/// - Restrained glowing tip at the arc head.
/// - Very subtle mint radial glow behind the gauge only.
/// - Explicit "Unavailable" state when [fillPercentage] is null.
/// - Full reduced-motion and accessibility support.
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
      // Only animate when the value meaningfully changed (> 0.05)
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
      return Color.lerp(const Color(0xFF48DF9F), AppColors.mintGreen, t)!;
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
              // Quiet track for offline state
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: widget.strokeWidth,
                  color: AppColors.slateOutlineVariant.withValues(alpha: 0.3),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sensors_off_rounded,
                    size: 26,
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
    final duration = AppMotion.duration(context, AppMotion.gaugeFill);
    final curve = AppMotion.prefersReducedMotion(context)
        ? Curves.linear
        : AppMotion.smoothCurve;

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: _previousPercentage, end: targetPercentage),
        duration: duration,
        curve: curve,
        builder: (context, animatedValue, child) {
          final currentColor = _getBlendedColor(animatedValue);
          final progress = (animatedValue / 100.0).clamp(0.0, 1.0);

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Very subtle mint radial glow behind the gauge only
                Container(
                  width: widget.size * 0.82,
                  height: widget.size * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mintGreen.withValues(alpha: 0.05),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Custom Painter for track, fill arc, and restrained glowing tip
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _GaugePainter(
                    progress: progress,
                    strokeWidth: widget.strokeWidth,
                    color: currentColor,
                    trackColor: const Color(0xFF141818),
                  ),
                ),

                // Center readout with clean typography
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
                        letterSpacing: 0.2,
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

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint (subtle low-contrast near-black ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Progress Arc Paint
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Restrained glowing tip at the arc head
    if (progress > 0.02) {
      final tipAngle = startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      final tipCenter = Offset(tipX, tipY);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(tipCenter, strokeWidth * 0.6, glowPaint);

      final highlightPaint = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(tipCenter, strokeWidth * 0.22, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}
