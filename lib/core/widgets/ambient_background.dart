import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-screen backdrop: dark gradient + slow-drifting colored "blobs".
///
/// Glass panels only look like glass if there's something behind them to
/// refract. A flat dark background makes BackdropFilter blur look like a
/// grey smudge. This widget provides the color and motion that makes the
/// frosted effect actually read as glass.
///
/// Usage: wrap a screen's Scaffold body in this, then place GlassContainer
/// panels on top.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Stack(
                  children: [
                    _blob(
                      color: AppColors.ambientBlobColors[0],
                      dx: size.width * (0.1 + 0.15 * (0.5 + 0.5 * _wave(t, 0))),
                      dy: size.height * (0.05 + 0.1 * (0.5 + 0.5 * _wave(t, 0.3))),
                      diameter: size.width * 0.8,
                    ),
                    _blob(
                      color: AppColors.ambientBlobColors[1],
                      dx: size.width * (0.5 + 0.2 * (0.5 + 0.5 * _wave(t, 0.6))),
                      dy: size.height * (0.5 + 0.15 * (0.5 + 0.5 * _wave(t, 0.9))),
                      diameter: size.width * 0.9,
                    ),
                    _blob(
                      color: AppColors.ambientBlobColors[2],
                      dx: size.width * (0.05 + 0.1 * (0.5 + 0.5 * _wave(t, 0.15))),
                      dy: size.height * (0.7 + 0.1 * (0.5 + 0.5 * _wave(t, 0.75))),
                      diameter: size.width * 0.7,
                    ),
                  ],
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  double _wave(double t, double phase) => 0.5 + 0.5 * (t + phase).remainder(1.0) * 2 - 1;

  Widget _blob({required Color color, required double dx, required double dy, required double diameter}) {
    return Positioned(
      left: dx - diameter / 2,
      top: dy - diameter / 2,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
