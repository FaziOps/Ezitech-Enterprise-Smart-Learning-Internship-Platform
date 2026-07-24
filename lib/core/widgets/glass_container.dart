import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// The single building block behind every glass-morphism surface in the app.
///
/// Why a shared widget instead of repeating BackdropFilter everywhere:
/// - Guarantees every panel uses the same blur, border, and gradient sheen,
///   so the app doesn't end up with a dozen slightly-different "glass" looks.
/// - Centralizes the one performance knob that matters: blur sigma. If glass
///   panels ever need to get cheaper on low-end Android devices, this is the
///   only file that changes.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
    this.blurSigma = AppGlass.blurSigma,
    this.fillColor = AppColors.glassFillLight,
    this.borderColor = AppColors.glassBorder,
    this.showHighlight = true,
    this.margin,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color fillColor;
  final Color borderColor;
  final bool showHighlight;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor, width: AppGlass.borderWidth),
              gradient: showHighlight
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(fillColor, AppColors.glassHighlight, 0.35)!,
                        fillColor,
                      ],
                    )
                  : null,
              color: showHighlight ? null : fillColor,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A tappable variant of [GlassContainer] with press feedback (subtle scale
/// + fill brighten) — used for cards that navigate somewhere (course cards,
/// dashboard tiles, assignment rows).
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: GlassContainer(
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          fillColor: _pressed ? AppColors.glassFillStrong : AppColors.glassFillLight,
          child: widget.child,
        ),
      ),
    );
  }
}
