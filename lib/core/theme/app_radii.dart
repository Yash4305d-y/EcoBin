import 'package:flutter/widgets.dart';

/// Centralized border radii tokens for EcoBin.
abstract final class AppRadii {
  // Numeric values
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  // Radius values
  static const Radius radiusNone = Radius.zero;
  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);
  static const Radius radiusXxl = Radius.circular(xxl);
  static const Radius radiusFull = Radius.circular(full);

  // BorderRadius helpers
  static const BorderRadius borderRadiusNone = BorderRadius.zero;
  static const BorderRadius borderRadiusXs = BorderRadius.all(radiusXs);
  static const BorderRadius borderRadiusSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderRadiusMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderRadiusLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderRadiusXl = BorderRadius.all(radiusXl);
  static const BorderRadius borderRadiusXxl = BorderRadius.all(radiusXxl);
  static const BorderRadius borderRadiusFull = BorderRadius.all(radiusFull);

  // Partial border radii for specialized components (sheets, banners)
  static const BorderRadius borderRadiusTopLg = BorderRadius.vertical(
    top: radiusLg,
  );
  static const BorderRadius borderRadiusTopXl = BorderRadius.vertical(
    top: radiusXl,
  );
}
