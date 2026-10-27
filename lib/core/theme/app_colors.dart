import 'package:flutter/material.dart';

/// Centralized color palette and design tokens for the EcoBin application.
///
/// Palette:
/// - Primary Background: Dark Navy
/// - Surfaces: Slate-colored tones
/// - Accent: Mint Green (IoT Eco branding)
/// - Typography: High-contrast white primary & muted blue-grey secondary
abstract final class AppColors {
  // Backgrounds
  static const Color darkNavy = Color(0xFF0A0F1D);
  static const Color darkNavyDeep = Color(0xFF060A14);
  static const Color darkNavyLight = Color(0xFF0F172A);

  // Surfaces (Slate Tones)
  static const Color slateSurface = Color(0xFF16203A);
  static const Color slateSurfaceVariant = Color(0xFF1E294B);
  static const Color slateSurfaceElevated = Color(0xFF24325C);
  static const Color slateSurfaceCard = Color(0xFF141C33);

  // Borders & Dividers
  static const Color slateOutline = Color(0xFF2B3C66);
  static const Color slateOutlineVariant = Color(0xFF1E2B4A);

  // Mint Green Accents
  static const Color mintGreen = Color(0xFF00E599);
  static const Color mintGreenHover = Color(0xFF33EBAD);
  static const Color mintGreenPressed = Color(0xFF00C782);
  static const Color mintGreenContainer = Color(0xFF0B3827);
  static const Color onMintGreen = Color(0xFF041910);
  static const Color onMintGreenContainer = Color(0xFF85F8CE);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC); // High-contrast white
  static const Color textSecondary = Color(0xFF94A3B8); // Muted blue-grey
  static const Color textTertiary = Color(0xFF64748B); // Deeper muted slate
  static const Color textDisabled = Color(0xFF475569); // Disabled slate

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFF064E3B);
  static const Color onSuccessContainer = Color(0xFF6EE7B7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFF78350F);
  static const Color onWarningContainer = Color(0xFFFDE68A);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFF7F1D1D);
  static const Color onErrorContainer = Color(0xFFFECACA);

  static const Color info = Color(0xFF38BDF8);
  static const Color infoContainer = Color(0xFF0C4A6E);
  static const Color onInfoContainer = Color(0xFFBAE6FD);

  // Accent Gradients
  static const LinearGradient mintGradient = LinearGradient(
    colors: [mintGreen, Color(0xFF00C9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [slateSurfaceVariant, slateSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
