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

  @visibleForTesting
  static void resetStaticMemory() {
    _AnimatedFillGaugeState.resetStaticMemory();
  }

  @override
  State<AnimatedFillGauge> createState() => _AnimatedFillGaugeState();
}

class _AnimatedFillGaugeState extends State<AnimatedFillGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  /// Retains the last known valid fill percentage across rebuilds and widget remounts,
  /// preventing the gauge from unexpectedly snapping or restarting its animation from zero.
  static double? _lastKnownPercentage;

  double? _lastTarget;

  @visibleForTesting
  static void resetStaticMemory() {
    _lastKnownPercentage = null;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.gaugeFill,
    );

    if (widget.fillPercentage != null) {
      final target = widget.fillPercentage!.clamp(0.0, 100.0);
      _lastTarget = target;
      final start = _lastKnownPercentage ?? target;
      _lastKnownPercentage = target;

      if ((start - target).abs() > 0.1) {
        _animation = Tween<double>(begin: start, end: target).animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.smoothCurve),
        );
        _controller.forward();
      } else {
        _animation = AlwaysStoppedAnimation<double>(target);
      }
    } else {
      _animation = AlwaysStoppedAnimation<double>(_lastKnownPercentage ?? 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedFillGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.fillPercentage == null) {
      // Sensor reading became unavailable.
      // Retain last known value in memory so that when reading resumes,
      // the gauge glides smoothly from its prior state rather than zero.
      _lastTarget = null;
      return;
    }

    final newTarget = widget.fillPercentage!.clamp(0.0, 100.0);
    _lastKnownPercentage = newTarget;

    // Requirement 8: Avoid restarting animations for tiny jitter (< 0.2%)
    if (_lastTarget != null && (newTarget - _lastTarget!).abs() < 0.2) {
      return;
    }

    final start = _animation.value;
    _lastTarget = newTarget;

    final duration = AppMotion.duration(context, AppMotion.gaugeFill);
    final curve = AppMotion.prefersReducedMotion(context)
        ? Curves.linear
        : AppMotion.smoothCurve;

    _controller.duration = duration;
    _animation = Tween<double>(
      begin: start,
      end: newTarget,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final animatedValue = _animation.value;
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
