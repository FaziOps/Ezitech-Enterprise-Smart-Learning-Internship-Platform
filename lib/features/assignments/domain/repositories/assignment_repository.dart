import '../../../../core/utils/failure.dart';
import '../entities/assignment_entity.dart';

abstract class AssignmentRepository {
  Future<Result<List<AssignmentEntity>>> getAssignments();

  Future<Result<AssignmentEntity>> getAssignmentDetail(String assignmentId);

  Future<Result<List<SubmissionEntity>>> getSubmissionHistory(String assignmentId);

  /// [filePath] is a local file path from file_picker; [githubLink] is
  /// optional. At least one must be provided — enforced by the use case,
  /// not here. Both are staged into the outbox; actual file bytes are
  /// uploaded by the sync handler when connectivity allows (large
  /// uploads are not attempted on a flaky connection inline).
  Future<void> submitAssignment({
    required String assignmentId,
    String? filePath,
    String? githubLink,
  });
}
