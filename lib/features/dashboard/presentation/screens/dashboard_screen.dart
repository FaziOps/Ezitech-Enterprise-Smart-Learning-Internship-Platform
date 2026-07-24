import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authControllerProvider).user;
    final isTablet = AppBreakpoints.isTablet(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          sliver: SliverToBoxAdapter(child: _Header(name: user.name.isEmpty ? 'Student' : user.name)),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: dashboardAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (err, st) => SliverToBoxAdapter(
              child: GlassContainer(
                child: Text('Could not load dashboard: $err'),
              ),
            ),
            data: (summary) => SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isTablet ? _TabletLayout(summary: summary) : _PhoneLayout(summary: summary),
                  const SizedBox(height: AppSpacing.md),
                  const _QuickAccessRow(),
                ],
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: TextStyle(color: AppColors.textMuted)),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GlassContainer(
                width: 44,
                height: 44,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: const Icon(Icons.notifications_outlined, size: 20),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.videocam_outlined,
            label: 'Live Learning',
            color: AppColors.warning,
            onTap: () => context.push('/live'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.workspace_premium_outlined,
            label: 'Portfolio',
            color: AppColors.aiAccent,
            onTap: () => context.push('/portfolio'),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProgressCard(
          title: summary.activeCourseTitle,
          subtitle: 'Active course',
          progress: summary.activeCourseProgress,
          icon: Icons.menu_book_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        _ProgressCard(
          title: summary.activeInternshipTitle,
          subtitle: 'Active internship',
          progress: summary.internshipProgress,
          icon: Icons.work_outline,
          accent: AppColors.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _ScoreAndTasksRow(summary: summary),
        const SizedBox(height: AppSpacing.md),
        _DeadlinesCard(deadlines: summary.upcomingDeadlines),
        const SizedBox(height: AppSpacing.md),
        _AiRecommendationsCard(recommendations: summary.aiRecommendations),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ProgressCard(
                title: summary.activeCourseTitle,
                subtitle: 'Active course',
                progress: summary.activeCourseProgress,
                icon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ProgressCard(
                title: summary.activeInternshipTitle,
                subtitle: 'Active internship',
                progress: summary.internshipProgress,
                icon: Icons.work_outline,
                accent: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ScoreAndTasksRow(summary: summary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _DeadlinesCard(deadlines: summary.upcomingDeadlines)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _AiRecommendationsCard(recommendations: summary.aiRecommendations),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.icon,
    this.accent = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final double progress;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.glassFillStrong,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('${(progress * 100).round()}% complete', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ScoreAndTasksRow extends StatelessWidget {
  const _ScoreAndTasksRow({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.warning, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Engineering Score', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const Spacer(),
              Text('${summary.engineeringScore}', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Text("Today's tasks", style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final task in summary.dailyTasks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: task.done ? AppColors.secondary : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.done ? TextDecoration.lineThrough : null,
                        color: task.done ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DeadlinesCard extends StatelessWidget {
  const _DeadlinesCard({required this.deadlines});
  final List<DeadlineItem> deadlines;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined, color: AppColors.danger, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Upcoming deadlines', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final d in deadlines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(d.title, overflow: TextOverflow.ellipsis)),
                  Text(
                    '${d.dueAt.difference(DateTime.now()).inDays}d left',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AiRecommendationsCard extends StatelessWidget {
  const _AiRecommendationsCard({required this.recommendations});
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      fillColor: AppColors.glassFillLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: AppColors.aiAccent, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('AI recommendations', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final r in recommendations)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('• $r', style: TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}
