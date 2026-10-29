import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';

/// Smooth animated rolling counter for percentage and numeric telemetry readouts.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.prefix = '',
    this.fractionDigits = 0,
    this.duration = AppMotion.gaugeFill,
    this.curve = AppMotion.smoothCurve,
  });

  final double value;
  final TextStyle? style;
  final String suffix;
  final String prefix;
  final int fractionDigits;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AppMotion.duration(context, duration);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: effectiveDuration,
      curve: curve,
      builder: (context, animValue, child) {
        final formatted = animValue.toStringAsFixed(fractionDigits);
        return Text(
          '$prefix$formatted$suffix',
          style: style ?? AppTextStyles.displaySmall,
        );
      },
    );
  }
}
