import 'package:flutter/material.dart';

/// Ezitech design tokens — colors.
///
/// The glass morphism system is built on a dark, gradient-driven background
/// (so frosted panels have something to refract) plus a small set of
/// saturated accent colors used sparingly for state and hierarchy.
class AppColors {
  AppColors._();

  // Background gradient stops (dark navy -> deep violet).
  static const Color bgTop = Color(0xFF0B1020);
  static const Color bgMid = Color(0xFF141B34);
  static const Color bgBottom = Color(0xFF1B1440);

  // Glass surface tints (white overlaid at low opacity on the dark bg).
  static const Color glassFillLight = Color(0x1FFFFFFF); // ~12% white
  static const Color glassFillStrong = Color(0x33FFFFFF); // ~20% white
  static const Color glassBorder = Color(0x3DFFFFFF); // ~24% white
  static const Color glassHighlight = Color(0x59FFFFFF); // top edge sheen

  // Accents
  static const Color primary = Color(0xFF6C8CFF); // indigo-blue
  static const Color primaryDeep = Color(0xFF4A63E0);
  static const Color secondary = Color(0xFF35D6C4); // teal, for progress/success
  static const Color warning = Color(0xFFFFB648);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color aiAccent = Color(0xFFB07CFF); // violet, reserved for AI assistant

  // Text
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xCCF5F7FF); // 80%
  static const Color textMuted = Color(0x99F5F7FF); // 60%
  static const Color textDisabled = Color(0x4DF5F7FF); // 30%

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgMid, bgBottom],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDeep],
  );

  /// Decorative background "blobs" used behind glass panels to give the
  /// frosted blur something colorful to pick up. Keep opacity low; these
  /// sit behind BackdropFilter layers.
  static const List<Color> ambientBlobColors = [
    Color(0x4D6C8CFF),
    Color(0x4035D6C4),
    Color(0x40B07CFF),
  ];
}
