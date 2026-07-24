import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/entities/analytics_entity.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(learningAnalyticsProvider);

    return ResponsiveCenter(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learning Analytics', style: Theme.of(context).textTheme.headlineSmall),
                  const Text(
                    'Your performance at a glance.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: analyticsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(
                child: GlassContainer(child: Text('Could not load analytics: $e')),
              ),
              data: (analytics) => SliverList(
                delegate: SliverChildListDelegate([
                  // Top KPIs
                  _KpiRow(analytics: analytics),
                  const SizedBox(height: AppSpacing.md),
                  // Weekly Activity Chart
                  _WeeklyActivityCard(activity: analytics.weeklyActivity),
                  const SizedBox(height: AppSpacing.md),
                  // Radial metrics
                  _MetricsRow(analytics: analytics),
                  const SizedBox(height: AppSpacing.md),
                  // Skill growth
                  _SkillGrowthCard(skills: analytics.skillGrowth),
                  const SizedBox(height: AppSpacing.md),
                  // Streaks
                  _StreakCard(current: analytics.currentStreak, longest: analytics.longestStreak),
                  const SizedBox(height: 96),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// KPI row
// ─────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.analytics});
  final LearningAnalyticsEntity analytics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _KpiTile(label: 'Total Hours', value: '${analytics.totalLearningHours.toStringAsFixed(1)}h', icon: Icons.schedule_outlined, color: AppColors.primary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _KpiTile(label: 'Day Streak', value: '${analytics.currentStreak}', icon: Icons.local_fire_department_outlined, color: AppColors.warning)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _KpiTile(label: 'Assignments', value: '${analytics.assignmentSuccessRate.round()}%', icon: Icons.assignment_turned_in_outlined, color: AppColors.secondary)),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Weekly activity bar chart
// ─────────────────────────────────────────────────────────────
class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.activity});
  final List<WeeklyActivityPoint> activity;

  @override
  Widget build(BuildContext context) {
    final maxMins = activity.map((a) => a.minutes).reduce(math.max);

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Activity', style: Theme.of(context).textTheme.labelLarge),
          const Text('Minutes of learning per day this week', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: activity.map((a) {
                final frac = maxMins == 0 ? 0.0 : a.minutes / maxMins;
                return _BarColumn(
                  label: a.day,
                  value: '${a.minutes}m',
                  fraction: frac,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({required this.label, required this.value, required this.fraction});
  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: AppMotion.slow,
          width: 28,
          height: math.max(4.0, fraction * 90),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withOpacity(0.9), AppColors.primaryDeep],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Circular metrics (completion, internship, assignment)
// ─────────────────────────────────────────────────────────────
class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.analytics});
  final LearningAnalyticsEntity analytics;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Metrics', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RadialMetric(
                label: 'Course\nCompletion',
                value: analytics.courseCompletionRate,
                color: AppColors.primary,
              ),
              _RadialMetric(
                label: 'Internship\nScore',
                value: analytics.internshipPerformanceScore,
                color: AppColors.secondary,
              ),
              _RadialMetric(
                label: 'Assignment\nSuccess',
                value: analytics.assignmentSuccessRate,
                color: AppColors.aiAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadialMetric extends StatelessWidget {
  const _RadialMetric({required this.label, required this.value, required this.color});
  final String label;
  final double value; // 0–100
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(80, 80),
                painter: _ArcPainter(fraction: value / 100, color: color),
              ),
              Text(
                '${value.round()}%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final trackPaint = Paint()
      ..color = AppColors.glassFillStrong
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Track
    canvas.drawCircle(center, radius, trackPaint);
    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.fraction != fraction;
}

// ─────────────────────────────────────────────────────────────
// Skill growth card
// ─────────────────────────────────────────────────────────────
class _SkillGrowthCard extends StatelessWidget {
  const _SkillGrowthCard({required this.skills});
  final List<SkillGrowthPoint> skills;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skill Growth', style: Theme.of(context).textTheme.labelLarge),
          const Text('Current level vs start of internship', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          for (final s in skills) ...[
            _SkillRow(skill: s),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill});
  final SkillGrowthPoint skill;

  @override
  Widget build(BuildContext context) {
    final gained = skill.level - skill.previousLevel;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(skill.skill, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                // Track
                Container(
                  height: 10,
                  color: AppColors.glassFillStrong,
                ),
                // Previous
                FractionallySizedBox(
                  widthFactor: skill.previousLevel / 5,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                // Current
                FractionallySizedBox(
                  widthFactor: skill.level / 5,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          gained > 0 ? '+$gained ▲' : '${skill.level}/5',
          style: TextStyle(
            fontSize: 11,
            color: gained > 0 ? AppColors.secondary : AppColors.textMuted,
            fontWeight: gained > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Streak card
// ─────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.current, required this.longest});
  final int current;
  final int longest;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, size: 36, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Learning Streak', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  '$current-day current streak',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Longest: $longest days',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$current 🔥',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
