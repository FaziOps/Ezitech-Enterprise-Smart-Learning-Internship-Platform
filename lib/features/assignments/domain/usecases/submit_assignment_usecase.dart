import '../../../../core/utils/failure.dart';
import '../repositories/assignment_repository.dart';

class SubmitAssignmentUseCase {
  const SubmitAssignmentUseCase(this._repository);

  final AssignmentRepository _repository;

  Future<Result<void>> call({
    required String assignmentId,
    String? filePath,
    String? githubLink,
  }) async {
    final hasFile = filePath != null && filePath.isNotEmpty;
    final hasLink = githubLink != null && githubLink.isNotEmpty;

    if (!hasFile && !hasLink) {
      return const Result.failure(
        ValidationFailure('Attach a file or a GitHub link before submitting.'),
      );
    }
    if (hasLink && !githubLink.startsWith('https://github.com/')) {
      return const Result.failure(
        ValidationFailure('GitHub link must start with https://github.com/'),
      );
    }

    await _repository.submitAssignment(
      assignmentId: assignmentId,
      filePath: filePath,
      githubLink: githubLink,
    );
    return const Result.success(null);
  }
}
