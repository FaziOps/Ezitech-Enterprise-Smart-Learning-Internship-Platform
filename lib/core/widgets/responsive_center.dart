import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Constrains content to a comfortable reading width on tablets instead
/// of letting single-column lists stretch edge-to-edge across a 10"+
/// screen. Phones pass through unchanged. Week 4's responsive-layout
/// pass added this to the list screens that only got phone-width
/// treatment when they were first built (Courses, Assignments,
/// Internship, Live, Portfolio) — Dashboard already had its own explicit
/// two-column tablet layout from Week 1.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isTablet(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
