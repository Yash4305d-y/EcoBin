import 'package:flutter/material.dart';

/// Centralized color palette and design tokens for the EcoBin application.
///
/// Final Visual Direction: Pitch Black + Mint
/// - Main Background: pure black #000000
/// - Primary Text: #F5F7F7
/// - Secondary Text: muted gray #929A9A
/// - Mint Accent: #70F0C0
/// - Secondary Surfaces: near-black #101313, used sparingly
/// - Dividers & Borders: subtle, low-contrast dark gray #1E2424
abstract final class AppColors {
  // Main Background (Pitch Black)
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkNavy = pureBlack;
  static const Color darkNavyDeep = pureBlack;
  static const Color darkNavyLight = Color(0xFF0A0C0C);

  // Secondary Surfaces (Near-Black #101313)
  static const Color surfaceNearBlack = Color(0xFF101313);
  static const Color surfaceElevated = Color(0xFF181C1C);
  static const Color slateSurface = surfaceNearBlack;
  static const Color slateSurfaceVariant = Color(0xFF151919);
  static const Color slateSurfaceElevated = surfaceElevated;
  static const Color slateSurfaceCard = surfaceNearBlack;

  // Borders & Dividers (Subtle low-contrast dark gray)
  static const Color borderSubtle = Color(0xFF1E2424);
  static const Color slateOutline = Color(0xFF262E2E);
  static const Color slateOutlineVariant = Color(0xFF1E2424);

  // Mint Accent (#70F0C0)
  static const Color mintGreen = Color(0xFF70F0C0);
  static const Color mintGreenHover = Color(0xFF8CF4CD);
  static const Color mintGreenPressed = Color(0xFF55E4AE);
  static const Color mintGreenContainer = Color(0xFF0D2E23);
  static const Color onMintGreen = Color(0xFF002115);
  static const Color onMintGreenContainer = Color(0xFF8DF7D0);

  // Typography
  static const Color textPrimary = Color(0xFFF5F7F7); // Crisp white
  static const Color textSecondary = Color(0xFF929A9A); // Muted gray
  static const Color textTertiary = Color(0xFF636C6C); // Deeper muted gray
  static const Color textDisabled = Color(0xFF424A4A); // Disabled gray

  // Status Colors (Thresholds)
  static const Color success = Color(0xFF70F0C0);
  static const Color successContainer = Color(0xFF0D2E23);
  static const Color onSuccessContainer = Color(0xFF8DF7D0);

  static const Color warning = Color(0xFFF5A623); // Yellow / amber threshold
  static const Color warningContainer = Color(0xFF382305);
  static const Color onWarningContainer = Color(0xFFFDE68A);

  static const Color error = Color(0xFFEF4444); // Red threshold
  static const Color errorContainer = Color(0xFF3D1111);
  static const Color onErrorContainer = Color(0xFFFECACA);

  static const Color info = Color(0xFF38BDF8);
  static const Color infoContainer = Color(0xFF0C334A);
  static const Color onInfoContainer = Color(0xFFBAE6FD);

  // Subtle Accent Gradients
  static const LinearGradient mintGradient = LinearGradient(
    colors: [mintGreen, Color(0xFF50D8A5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF131717), Color(0xFF0F1212)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
