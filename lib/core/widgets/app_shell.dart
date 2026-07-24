import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'ambient_background.dart';
import 'glass_container.dart';

/// Persistent shell for all authenticated routes: ambient background +
/// a floating glass bottom navigation bar with overflow menu for extra tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  // Primary bottom-nav tabs (always visible)
  static const _primaryTabs = [
    _TabDef('Dashboard', Icons.space_dashboard_outlined, '/dashboard'),
    _TabDef('Courses', Icons.menu_book_outlined, '/courses'),
    _TabDef('Internship', Icons.work_outline, '/internship'),
    _TabDef('Tasks', Icons.assignment_outlined, '/assignments'),
    _TabDef('AI', Icons.auto_awesome_outlined, '/ai-assistant'),
  ];

  // Secondary tabs accessible via "More" menu
  static const _moreTabs = [
    _TabDef('Live', Icons.live_tv_outlined, '/live'),
    _TabDef('Portfolio', Icons.badge_outlined, '/portfolio'),
    _TabDef('Community', Icons.forum_outlined, '/community'),
    _TabDef('Analytics', Icons.bar_chart_outlined, '/analytics'),
    _TabDef('Downloads', Icons.download_outlined, '/downloads'),
    _TabDef('Alerts', Icons.notifications_outlined, '/notifications'),
  ];

  int? _indexForLocation(String location) {
    final index = _primaryTabs.indexWhere((t) => location.startsWith(t.path));
    return index == -1 ? null : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      extendBody: true,
      body: AmbientBackground(child: SafeArea(bottom: false, child: child)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _primaryTabs.length; i++)
                  _NavItem(
                    tab: _primaryTabs[i],
                    selected: i == currentIndex,
                    onTap: () => context.go(_primaryTabs[i].path),
                  ),
                // More button
                _MoreButton(moreTabs: _moreTabs, currentLocation: location),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.onTap});

  final _TabDef tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.glassFillStrong : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(tab.label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// "More" button that opens a bottom sheet listing the secondary tabs.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.moreTabs, required this.currentLocation});
  final List<_TabDef> moreTabs;
  final String currentLocation;

  bool get _anyMoreActive => moreTabs.any((t) => currentLocation.startsWith(t.path));

  @override
  Widget build(BuildContext context) {
    final color = _anyMoreActive ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _showMoreSheet(context),
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: _anyMoreActive ? AppColors.glassFillStrong : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, color: color, size: 22),
            const SizedBox(height: 2),
            Text('More', style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreSheet(moreTabs: moreTabs, currentLocation: currentLocation),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.moreTabs, required this.currentLocation});
  final List<_TabDef> moreTabs;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.2)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Text('More', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.1,
            children: moreTabs.map((tab) {
              final selected = currentLocation.startsWith(tab.path);
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.go(tab.path);
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.glassFillLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.glassBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 26,
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
