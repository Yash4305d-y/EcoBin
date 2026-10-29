import 'package:flutter/material.dart';

/// Centralized motion design system for EcoBin.
///
/// Provides spring presets, timing tokens, easing curves, and accessibility
/// helpers to ensure restrained, premium consumer hardware motion across the app.
abstract final class EcoMotion {
  // --- Spring Presets ---
  /// Snappy spring for micro-interactions, button presses, and tactile feedback.
  static const SpringDescription snappy = SpringDescription(
    mass: 1.0,
    stiffness: 350.0,
    damping: 24.0,
  );

  /// Smooth spring for gauge fill and status transitions.
  static const SpringDescription smooth = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 20.0,
  );

  /// Gentle spring for page entrances, modal sheets, and large surface reveals.
  static const SpringDescription gentle = SpringDescription(
    mass: 1.0,
    stiffness: 110.0,
    damping: 16.0,
  );

  // --- Durations ---
  /// 150 ms for micro-interactions, scales, and instant feedback.
  static const Duration micro = Duration(milliseconds: 150);

  /// 250 ms for status changes and chip transitions.
  static const Duration fast = Duration(milliseconds: 250);

  /// 300 ms standard transition duration.
  static const Duration standard = Duration(milliseconds: 300);

  /// 300 ms for tab and page transitions.
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// 380 ms for detailed modal / screen push transitions.
  static const Duration detailTransition = Duration(milliseconds: 380);

  /// 750 ms for fill gauge fluid transitions.
  static const Duration gaugeFill = Duration(milliseconds: 750);

  /// 60 ms stagger delay between sequential list / card entrances.
  static const Duration staggerDelay = Duration(milliseconds: 60);

  // --- Curves ---
  /// Cubic ease out for entrances and incoming elements.
  static const Curve enterCurve = Curves.easeOutCubic;

  /// Smooth ease in/out for state changes and color transitions.
  static const Curve stateChangeCurve = Curves.easeInOut;

  /// Restrained overshoot for tactile feedback.
  static const Curve popFeedbackCurve = Curves.easeOutBack;

  /// Snappy curve for quick micro-interactions.
  static const Curve snappyCurve = Curves.easeOutQuad;

  /// Smooth cubic curve for gauge and fluid motions.
  static const Curve smoothCurve = Curves.easeInOutCubic;

  /// Gentle curve for entrances and expansions.
  static const Curve gentleCurve = Curves.easeOut;

  // --- Accessibility Helpers ---
  /// Checks whether the user has requested reduced motion or disabled animations.
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Returns [original] duration or [Duration.zero] if reduced motion is enabled.
  static Duration duration(BuildContext context, Duration original) {
    if (prefersReducedMotion(context)) {
      return Duration.zero;
    }
    return original;
  }
}
