import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/offline_indicator.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/entities/assignment_entity.dart';
import '../providers/assignment_providers.dart';

class AssignmentListScreen extends ConsumerWidget {
  const AssignmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsListProvider);

    return ResponsiveCenter(
      child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(child: Text('Assignments', style: Theme.of(context).textTheme.headlineSmall)),
                const OfflineIndicator(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: assignmentsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => SliverToBoxAdapter(child: GlassContainer(child: Text('Error: $e'))),
            data: (assignments) => SliverList.separated(
              itemCount: assignments.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _AssignmentCard(
                assignment: assignments[i],
                onTap: () => context.push('/assignments/${assignments[i].id}'),
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.onTap});

  final AssignmentEntity assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final daysLeft = assignment.dueAt.difference(DateTime.now()).inDays;
    final (statusLabel, statusColor) = switch (assignment.status) {
      AssignmentStatus.pending =>
        assignment.isOverdue ? ('Overdue', AppColors.danger) : ('Pending', AppColors.warning),
      AssignmentStatus.submitted => ('Submitted', AppColors.secondary),
      AssignmentStatus.evaluated => ('Evaluated · ${assignment.evaluationScore}/100', AppColors.primary),
    };

    return GlassCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            assignment.status == AssignmentStatus.pending
                ? (daysLeft >= 0 ? '$daysLeft days left' : 'Overdue by ${-daysLeft} days')
                : 'Due ${assignment.dueAt.day}/${assignment.dueAt.month}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
