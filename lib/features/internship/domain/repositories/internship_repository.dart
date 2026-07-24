import '../../../../core/utils/failure.dart';
import '../entities/internship_entity.dart';

abstract class InternshipRepository {
  Future<Result<CaseStudyEntity>> getAssignedCaseStudy();

  Future<Result<List<InternshipTaskEntity>>> getDailyTasks();

  Future<void> toggleTaskDone(String taskId, bool done);

  Future<Result<List<MentorFeedbackEntity>>> getMentorFeedback();

  Future<Result<List<WeeklyReportEntity>>> getSubmittedReports();

  /// Optimistic: appears in submitted-reports list immediately with
  /// `synced: false`; the outbox pushes it to the server in the
  /// background and flips it to synced once confirmed.
  Future<void> submitWeeklyReport({
    required int weekNumber,
    required String summary,
    String? githubLink,
  });
}
