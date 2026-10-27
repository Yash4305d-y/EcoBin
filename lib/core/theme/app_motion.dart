import 'package:flutter/material.dart';

/// Centralized motion design tokens and animation constants for EcoBin.
///
/// Follows strict timing standards:
/// - Micro-interactions: 150 ms
/// - Standard transitions: 250–350 ms
/// - Page transitions: 300 ms
/// - Gauge fill: 600–900 ms (750 ms standard)
/// - Stagger delay: ~60 ms
///
/// Curves:
/// - Entering: Curves.easeOutCubic
/// - State changes: Curves.easeInOut
/// - Pop feedback: Curves.easeOutBack
abstract final class AppMotion {
  // Durations
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration detailTransition = Duration(milliseconds: 380);
  static const Duration gaugeFill = Duration(milliseconds: 750);
  static const Duration staggerDelay = Duration(milliseconds: 60);

  // Curves
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve stateChangeCurve = Curves.easeInOut;
  static const Curve popFeedbackCurve = Curves.easeOutBack;

  /// Returns [original] duration or [Duration.zero] if the user has requested
  /// reduced motion via accessibility settings.
  static Duration duration(BuildContext context, Duration original) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return Duration.zero;
    }
    return original;
  }
}
