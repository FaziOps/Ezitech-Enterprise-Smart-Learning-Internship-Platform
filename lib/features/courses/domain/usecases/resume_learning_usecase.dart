import '../entities/course_entity.dart';
import '../repositories/course_repository.dart';

/// Encapsulates the "what lesson does the student see when they tap
/// Resume Learning" business rule: last-viewed lesson if progress
/// exists, otherwise the first lesson in course order. Kept out of the
/// widget layer so this logic is unit-testable and reusable from both
/// the Dashboard and the Course Detail screen.
class ResumeLearningUseCase {
  const ResumeLearningUseCase(this._repository);

  final CourseRepository _repository;

  Future<LessonEntity?> call(String courseId) => _repository.resumeLessonFor(courseId);
}
