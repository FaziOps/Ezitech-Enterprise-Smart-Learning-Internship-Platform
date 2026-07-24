import '../../../../core/utils/failure.dart';
import '../repositories/internship_repository.dart';

/// Business rule: a weekly report must have a non-trivial summary before
/// it's allowed into the outbox — catching this here means the UI layer
/// doesn't have to duplicate the same length check.
class SubmitWeeklyReportUseCase {
  const SubmitWeeklyReportUseCase(this._repository);

  final InternshipRepository _repository;

  Future<Result<void>> call({
    required int weekNumber,
    required String summary,
    String? githubLink,
  }) async {
    if (summary.trim().length < 20) {
      return const Result.failure(
        ValidationFailure('Weekly report summary should be at least 20 characters.'),
      );
    }
    if (githubLink != null &&
        githubLink.isNotEmpty &&
        !githubLink.startsWith('https://github.com/')) {
      return const Result.failure(
        ValidationFailure('GitHub link must start with https://github.com/'),
      );
    }

    await _repository.submitWeeklyReport(
      weekNumber: weekNumber,
      summary: summary.trim(),
      githubLink: githubLink,
    );
    return const Result.success(null);
  }
}
