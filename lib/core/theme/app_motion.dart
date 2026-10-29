import 'package:flutter/material.dart';

import '../motion.dart';

export '../motion.dart';

/// Centralized motion design tokens and animation constants for EcoBin.
///
/// Aliases the core [EcoMotion] system to preserve compatibility with existing
/// call-sites and bottom navigation animation references.
abstract final class AppMotion {
  // Spring Presets
  static const SpringDescription snappy = EcoMotion.snappy;
  static const SpringDescription smooth = EcoMotion.smooth;
  static const SpringDescription gentle = EcoMotion.gentle;

  // Durations
  static const Duration micro = EcoMotion.micro;
  static const Duration fast = EcoMotion.fast;
  static const Duration standard = EcoMotion.standard;
  static const Duration pageTransition = EcoMotion.pageTransition;
  static const Duration detailTransition = EcoMotion.detailTransition;
  static const Duration gaugeFill = EcoMotion.gaugeFill;
  static const Duration staggerDelay = EcoMotion.staggerDelay;

  // Curves
  static const Curve enterCurve = EcoMotion.enterCurve;
  static const Curve stateChangeCurve = EcoMotion.stateChangeCurve;
  static const Curve popFeedbackCurve = EcoMotion.popFeedbackCurve;
  static const Curve snappyCurve = EcoMotion.snappyCurve;
  static const Curve smoothCurve = EcoMotion.smoothCurve;
  static const Curve gentleCurve = EcoMotion.gentleCurve;

  /// Returns [original] duration or [Duration.zero] if the user has requested
  /// reduced motion via accessibility settings.
  static Duration duration(BuildContext context, Duration original) {
    return EcoMotion.duration(context, original);
  }

  /// Whether reduced motion is requested.
  static bool prefersReducedMotion(BuildContext context) {
    return EcoMotion.prefersReducedMotion(context);
  }
}
