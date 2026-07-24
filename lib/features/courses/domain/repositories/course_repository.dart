import '../../../../core/utils/failure.dart';
import '../entities/course_entity.dart';

abstract class CourseRepository {
  /// Offline-first: returns cached courses immediately if present, then
  /// the caller (provider) issues a background refresh. See
  /// CourseRepositoryImpl for the cache-then-network pattern.
  Future<Result<List<CourseEntity>>> getCourses();

  Future<Result<CourseDetailEntity>> getCourseDetail(String courseId);

  Future<Result<CourseProgressEntity>> getProgress(String courseId);

  /// Optimistic write: updates local cache immediately and enqueues an
  /// outbox item for background sync — never awaits the network.
  Future<void> markLessonComplete(String courseId, String lessonId);

  Future<void> updateLastPosition(String courseId, String lessonId, int positionSeconds);

  Future<Result<List<NoteEntity>>> getNotes(String lessonId);

  Future<void> addNote(String lessonId, String content);

  /// Downloads video/PDF assets for offline viewing — Downloads module
  /// overlaps with this; kept here since it's course-scoped.
  Future<Result<void>> downloadForOffline(String courseId);

  /// Given all courses + progress, determines which lesson to resume —
  /// used by the Dashboard's "Resume Learning" action and here directly.
  Future<LessonEntity?> resumeLessonFor(String courseId);
}
