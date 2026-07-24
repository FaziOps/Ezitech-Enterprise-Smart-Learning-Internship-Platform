import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/offline_indicator.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/entities/internship_entity.dart';
import '../providers/internship_providers.dart';

class InternshipScreen extends ConsumerWidget {
  const InternshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseStudyAsync = ref.watch(caseStudyProvider);
    final tasksAsync = ref.watch(internshipTasksProvider);
    final feedbackAsync = ref.watch(mentorFeedbackProvider);
    final reportsAsync = ref.watch(submittedReportsProvider);

    return ResponsiveCenter(
      child: ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
      children: [
        Row(
          children: [
            Expanded(child: Text('Internship Portal', style: Theme.of(context).textTheme.headlineSmall)),
            const OfflineIndicator(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        caseStudyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => GlassContainer(child: Text('Could not load case study: $e')),
          data: (cs) => _CaseStudyCard(caseStudy: cs),
        ),
        const SizedBox(height: AppSpacing.md),
        tasksAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
          data: (tasks) => _DailyTasksCard(tasks: tasks),
        ),
        const SizedBox(height: AppSpacing.md),
        const _WeeklyReportForm(),
        const SizedBox(height: AppSpacing.md),
        reportsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
          data: (reports) =>
              reports.isEmpty ? const SizedBox.shrink() : _SubmittedReportsCard(reports: reports),
        ),
        const SizedBox(height: AppSpacing.md),
        feedbackAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
          data: (feedback) => _MentorFeedbackCard(feedback: feedback),
        ),
      ],
      ),
    );
  }
}

class _CaseStudyCard extends StatelessWidget {
  const _CaseStudyCard({required this.caseStudy});
  final CaseStudyEntity caseStudy;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline, color: AppColors.secondary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Assigned Case Study', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(caseStudy.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(caseStudy.description, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: caseStudy.currentWeek / caseStudy.durationWeeks,
              minHeight: 8,
              backgroundColor: AppColors.glassFillStrong,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Week ${caseStudy.currentWeek} of ${caseStudy.durationWeeks}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DailyTasksCard extends ConsumerWidget {
  const _DailyTasksCard({required this.tasks});
  final List<InternshipTaskEntity> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Tasks', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final task in tasks)
            CheckboxListTile(
              value: task.done,
              onChanged: (value) async {
                await ref
                    .read(internshipRepositoryProvider)
                    .toggleTaskDone(task.id, value ?? false);
                ref.invalidate(internshipTasksProvider);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.secondary,
              title: Text(task.title),
              subtitle: Text(task.dayLabel, style: const TextStyle(color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }
}

class _WeeklyReportForm extends ConsumerStatefulWidget {
  const _WeeklyReportForm();

  @override
  ConsumerState<_WeeklyReportForm> createState() => _WeeklyReportFormState();
}

class _WeeklyReportFormState extends ConsumerState<_WeeklyReportForm> {
  final _summaryController = TextEditingController();
  final _githubController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _summaryController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref.read(submitWeeklyReportUseCaseProvider).call(
          weekNumber: 2,
          summary: _summaryController.text,
          githubLink: _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        _summaryController.clear();
        _githubController.clear();
        ref.invalidate(submittedReportsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly report saved — will sync when online.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submit Weekly Report', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _summaryController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'What did you build/learn this week?',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _githubController,
            decoration: const InputDecoration(
              hintText: 'https://github.com/you/repo (optional)',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedReportsCard extends StatelessWidget {
  const _SubmittedReportsCard({required this.reports});
  final List<WeeklyReportEntity> reports;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submission History', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final r in reports)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    r.synced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                    size: 16,
                    color: r.synced ? AppColors.secondary : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Week ${r.weekNumber}', overflow: TextOverflow.ellipsis)),
                  Text(
                    r.synced ? 'Synced' : 'Pending sync',
                    style: TextStyle(
                      fontSize: 12,
                      color: r.synced ? AppColors.textMuted : AppColors.warning,
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

class _MentorFeedbackCard extends StatelessWidget {
  const _MentorFeedbackCard({required this.feedback});
  final List<MentorFeedbackEntity> feedback;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mentor Feedback', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final f in feedback)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(f.mentorName, style: Theme.of(context).textTheme.labelMedium),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < f.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(f.message, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
