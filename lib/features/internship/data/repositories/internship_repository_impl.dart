import 'package:uuid/uuid.dart';
import '../../../../core/offline/outbox_item.dart';
import '../../../../core/offline/outbox_queue.dart';
import '../../../../core/utils/failure.dart';
import '../../domain/entities/internship_entity.dart';
import '../../domain/repositories/internship_repository.dart';
import '../datasources/internship_local_datasource.dart';
import '../datasources/internship_remote_datasource.dart';
import '../models/internship_model.dart';

class InternshipRepositoryImpl implements InternshipRepository {
  InternshipRepositoryImpl(this._remote, this._local, this._outbox);

  final InternshipRemoteDataSource _remote;
  final InternshipLocalDataSource _local;
  final OutboxQueue _outbox;
  final _uuid = const Uuid();

  @override
  Future<Result<CaseStudyEntity>> getAssignedCaseStudy() async {
    try {
      return Result.success(await _remote.getAssignedCaseStudy());
    } catch (_) {
      // No live Internship Portal endpoint yet (README API table #3) —
      // seed with the FLUTR-002 case study itself so the module is
      // demoable end-to-end today.
      return const Result.success(CaseStudyModel(
        id: 'flutr-002',
        title: 'FLUTTER-002: Enterprise Smart Learning & Internship Platform',
        description:
            'Design and build a cross-platform learning and internship mobile '
            'app integrating the Ezitech LMS, Internship Portal, AI Services, '
            'and Project Management System.',
        durationWeeks: 4,
        currentWeek: 2,
      ));
    }
  }

  @override
  Future<Result<List<InternshipTaskEntity>>> getDailyTasks() async {
    try {
      final tasks = await _remote.getDailyTasks();
      await _local.cacheTasks(tasks);
      return Result.success(tasks);
    } catch (_) {
      final cached = _local.getCachedTasks();
      if (cached.isNotEmpty) return Result.success(cached);
      final seeded = _seedTasks();
      await _local.cacheTasks(seeded);
      return Result.success(seeded);
    }
  }

  List<InternshipTaskModel> _seedTasks() => const [
        InternshipTaskModel(id: 'it1', title: 'Build offline outbox queue', done: true, dayLabel: 'Mon'),
        InternshipTaskModel(id: 'it2', title: 'Wire Internship Portal repository', done: true, dayLabel: 'Tue'),
        InternshipTaskModel(id: 'it3', title: 'Build Course Management module', done: false, dayLabel: 'Wed'),
        InternshipTaskModel(id: 'it4', title: 'Submit Week 2 weekly report', done: false, dayLabel: 'Fri'),
      ];

  @override
  Future<void> toggleTaskDone(String taskId, bool done) async {
    await _local.setTaskDone(taskId, done);
    await _outbox.enqueue(OutboxItem(
      id: _uuid.v4(),
      payloadType: 'internship_task_toggle',
      payloadJson: {'id': taskId, 'done': done},
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Result<List<MentorFeedbackEntity>>> getMentorFeedback() async {
    try {
      return Result.success(await _remote.getMentorFeedback());
    } catch (_) {
      return Result.success([
        MentorFeedbackModel(
          id: 'mf1',
          mentorName: 'Ayesha Raza',
          message: 'Good separation of concerns in the auth repository — keep the same '
              'discipline as you add Internship and Assignments.',
          givenAt: DateTime.now().subtract(const Duration(days: 1)),
          rating: 4,
        ),
      ]);
    }
  }

  @override
  Future<Result<List<WeeklyReportEntity>>> getSubmittedReports() async {
    return Result.success(_local.getCachedReports());
  }

  @override
  Future<void> submitWeeklyReport({
    required int weekNumber,
    required String summary,
    String? githubLink,
  }) async {
    final report = WeeklyReportModel(
      id: _uuid.v4(),
      weekNumber: weekNumber,
      summary: summary,
      githubLink: githubLink,
      submittedAt: DateTime.now(),
      synced: false,
    );
    await _local.addLocalReport(report);
    await _outbox.enqueue(OutboxItem(
      id: report.id,
      payloadType: OutboxPayloadType.weeklyReport,
      payloadJson: report.toJson(),
      createdAt: DateTime.now(),
    ));
  }

  /// Called by SyncWorker when a weekly_report outbox item drains.
  Future<void> syncWeeklyReport(Map<String, dynamic> payload) async {
    await _remote.syncWeeklyReport(payload);
    await _local.markReportSynced(payload['id'] as String);
  }

  /// Called by SyncWorker for internship_task_toggle items.
  Future<void> syncTaskToggle(Map<String, dynamic> payload) async {
    await _remote.syncTaskState(payload);
  }
}
