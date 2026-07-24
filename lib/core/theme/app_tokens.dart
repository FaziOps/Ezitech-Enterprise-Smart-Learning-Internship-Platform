import 'package:flutter/widgets.dart';

/// Spacing scale — always use these instead of raw numbers so density
/// stays consistent across screens.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii. Glass morphism reads as "soft" — nothing sharp.
class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 999;
}

/// Blur + glass panel constants.
class AppGlass {
  AppGlass._();
  static const double blurSigma = 18;
  static const double blurSigmaStrong = 28;
  static const double borderWidth = 1.2;
}

/// Breakpoints for responsive layout (phone vs tablet).
class AppBreakpoints {
  AppBreakpoints._();
  static const double tablet = 720;
  static const double desktop = 1200;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

/// Motion durations/curves so animation feel is consistent everywhere.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
}
