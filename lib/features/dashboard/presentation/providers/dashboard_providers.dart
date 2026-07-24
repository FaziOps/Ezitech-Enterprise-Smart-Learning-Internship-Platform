import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../assignments/domain/entities/assignment_entity.dart';
import '../../../assignments/presentation/providers/assignment_providers.dart';
import '../../../courses/presentation/providers/course_providers.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../domain/entities/dashboard_entity.dart';

/// Week 2 change: this provider no longer returns hand-typed mock data.
/// It composes the Dashboard's summary from the real Courses, Internship,
/// and Assignments repositories built this week — each of which still
/// falls back to seed data internally when no live backend is connected
/// (see each repository's `_seed...()` method), so this stays demoable
/// without a backend while being structurally "live" already: once the
/// LMS/Internship/Assignment APIs are connected, this provider needs no
/// changes at all.
final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final courses = await ref.watch(coursesListProvider.future);
  final caseStudy = await ref.watch(caseStudyProvider.future);
  final internshipTasks = await ref.watch(internshipTasksProvider.future);
  final assignments = await ref.watch(assignmentsListProvider.future);

  final activeCourse = courses.isNotEmpty ? courses.first : null;

  final upcomingDeadlines = assignments
      .where((a) => a.status != AssignmentStatus.evaluated)
      .map((a) => DeadlineItem(id: a.id, title: a.title, dueAt: a.dueAt))
      .toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  final dailyTasks =
      internshipTasks.map((t) => TaskItem(id: t.id, title: t.title, done: t.done)).toList();

  final completedCourseLessons = courses.fold<int>(0, (sum, c) => sum + c.completedLessons);
  final engineeringScore = 500 + completedCourseLessons * 20 + caseStudy.currentWeek * 30;

  return DashboardSummary(
    activeCourseTitle: activeCourse?.title ?? 'No active course yet',
    activeCourseProgress: activeCourse?.progress ?? 0,
    activeInternshipTitle: caseStudy.title,
    internshipProgress: caseStudy.currentWeek / caseStudy.durationWeeks,
    dailyTasks: dailyTasks,
    upcomingDeadlines: upcomingDeadlines.take(3).toList(),
    aiRecommendations: const [
      'Review Riverpod AsyncNotifier patterns before Week 3',
      'Revisit offline outbox retry/backoff before Live Learning ships',
    ],
    engineeringScore: engineeringScore,
  );
});
