import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';

class StudyDay {
  const StudyDay({required this.day, required this.tasks, required this.estimatedHours});
  final String day;
  final List<String> tasks;
  final double estimatedHours;
}

class StudyPlan {
  const StudyPlan({required this.week, required this.goal, required this.days, required this.totalHours});
  final int week;
  final String goal;
  final List<StudyDay> days;
  final double totalHours;
}

/// Simulates AI-generated weekly study plan generation.
/// Replace the delay with a real Dio POST to the AI Services endpoint.
final studyPlanProvider = FutureProvider<StudyPlan?>((ref) async => null);

class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> {
  final _goalCtrl = TextEditingController();
  StudyPlan? _generatedPlan;
  bool _generating = false;

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    if (_goalCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);
    // Simulate AI API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _generating = false;
      _generatedPlan = _buildPlan(_goalCtrl.text.trim());
    });
  }

  StudyPlan _buildPlan(String goal) {
    return StudyPlan(
      week: DateTime.now().weekday,
      goal: goal,
      totalHours: 18.0,
      days: [
        const StudyDay(day: 'Monday', estimatedHours: 2.5, tasks: [
          'Watch Flutter Clean Architecture – Lesson 4 (45 min)',
          'Read Riverpod documentation chapter 3 (30 min)',
          'Complete daily internship task (45 min)',
        ]),
        const StudyDay(day: 'Tuesday', estimatedHours: 3.0, tasks: [
          'Implement Offline Sync – Outbox pattern practice (60 min)',
          'Assignment 2: Case Study analysis (60 min)',
          'Review mentor feedback from last week (30 min)',
        ]),
        const StudyDay(day: 'Wednesday', estimatedHours: 2.0, tasks: [
          'Video: GoRouter advanced patterns (45 min)',
          'Submit weekly internship report (30 min)',
          'Self-assessment quiz – Dart language (30 min)',
        ]),
        const StudyDay(day: 'Thursday', estimatedHours: 4.0, tasks: [
          'Live class – Week 3 Architecture Review (60 min)',
          'Build Downloads screen feature (90 min)',
          'Push code to GitHub with PR description (30 min)',
        ]),
        const StudyDay(day: 'Friday', estimatedHours: 3.0, tasks: [
          'Complete remaining assignment & upload file (60 min)',
          'Watch Session Recording from Thursday\'s class (45 min)',
          'Review peer\'s code in Community tab (30 min)',
        ]),
        const StudyDay(day: 'Saturday', estimatedHours: 2.5, tasks: [
          'Bonus: Implement QR attendance feature (120 min)',
          'Update Engineering Portfolio with new project (30 min)',
        ]),
        const StudyDay(day: 'Sunday', estimatedHours: 1.0, tasks: [
          'Reflect on week, update study notes (30 min)',
          'Plan tasks for next week (30 min)',
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: AppColors.aiAccent, size: 20),
            SizedBox(width: AppSpacing.xs),
            Text('AI Study Planner'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
        children: [
          // Input section
          GlassContainer(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What is your learning goal this week?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'e.g. "Finish the offline sync module and submit assignment 2"',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _goalCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe your weekly goal…',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _generatePlan,
                    icon: _generating
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(_generating ? 'Generating plan…' : 'Generate Study Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aiAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_generatedPlan != null) ...[
            const SizedBox(height: AppSpacing.md),
            // Plan header
            GlassContainer(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined, color: AppColors.aiAccent, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Week Plan', style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          'Goal: ${_generatedPlan!.goal}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.aiAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${_generatedPlan!.totalHours}h total',
                      style: const TextStyle(fontSize: 12, color: AppColors.aiAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Day-by-day plan
            for (final day in _generatedPlan!.days) ...[
              _DayCard(day: day),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _DayCard extends StatefulWidget {
  const _DayCard({required this.day});
  final StudyDay day;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;
  final Set<int> _completedTasks = {};

  @override
  Widget build(BuildContext context) {
    final completed = _completedTasks.length;
    final total = widget.day.tasks.length;

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: completed == total
                        ? AppColors.secondary.withOpacity(0.2)
                        : AppColors.aiAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    completed == total ? Icons.check_circle : Icons.calendar_today_outlined,
                    size: 20,
                    color: completed == total ? AppColors.secondary : AppColors.aiAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.day.day, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        '$completed/$total tasks · ${widget.day.estimatedHours}h estimated',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          // Progress bar
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              backgroundColor: AppColors.glassFillStrong,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
              minHeight: 4,
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < widget.day.tasks.length; i++)
              CheckboxListTile(
                value: _completedTasks.contains(i),
                onChanged: (v) => setState(() {
                  if (v == true) _completedTasks.add(i); else _completedTasks.remove(i);
                }),
                title: Text(
                  widget.day.tasks[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: _completedTasks.contains(i) ? AppColors.textMuted : AppColors.textPrimary,
                    decoration: _completedTasks.contains(i) ? TextDecoration.lineThrough : null,
                  ),
                ),
                activeColor: AppColors.secondary,
                checkColor: Colors.white,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ],
      ),
    );
  }
}
