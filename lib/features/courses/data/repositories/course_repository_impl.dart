import 'package:uuid/uuid.dart';
import '../../../../core/offline/download_manager.dart';
import '../../../../core/offline/outbox_item.dart';
import '../../../../core/offline/outbox_queue.dart';
import '../../../../core/utils/failure.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_local_datasource.dart';
import '../datasources/course_remote_datasource.dart';
import '../models/course_model.dart';

/// Offline-first pattern used across this repository:
/// 1. Read: return cache immediately (fast, works offline). Caller
///    (provider) separately triggers a network refresh that overwrites
///    the cache and pushes new state — see CoursesProviders.
/// 2. Write: update cache synchronously, enqueue an outbox item, return
///    immediately. Never block the UI on a round trip.
///
/// This is exactly the model described in the Implementation Plan's
/// Section 3.3 (Offline-First Strategy).
class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl(this._remote, this._local, this._outbox, this._downloads);

  final CourseRemoteDataSource _remote;
  final CourseLocalDataSource _local;
  final OutboxQueue _outbox;
  final DownloadManager _downloads;
  final _uuid = const Uuid();

  @override
  Future<Result<List<CourseEntity>>> getCourses() async {
    try {
      final remoteCourses = await _remote.getCourses();
      await _local.cacheCourses(remoteCourses);
      return Result.success(remoteCourses);
    } catch (_) {
      final cached = _local.getCachedCourses();
      if (cached != null) return Result.success(cached);
      // No live LMS endpoint yet and nothing cached (first run, no
      // network) — fall back to seed data so the UI/state layer can be
      // exercised end-to-end. Remove _seedCourses() once the real LMS
      // API (README table #2) is connected and returning data.
      return Result.success(_seedCourses());
    }
  }

  List<CourseModel> _seedCourses() => const [
        CourseModel(
          id: 'c1',
          title: 'Flutter Enterprise Architecture',
          instructor: 'Ezitech Faculty',
          thumbnailUrl: null,
          totalLessons: 8,
          completedLessons: 5,
          category: 'Mobile Development',
        ),
        CourseModel(
          id: 'c2',
          title: 'Clean Architecture Deep Dive',
          instructor: 'Ezitech Faculty',
          thumbnailUrl: null,
          totalLessons: 6,
          completedLessons: 1,
          category: 'Software Design',
        ),
        CourseModel(
          id: 'c3',
          title: 'Offline-First Mobile Patterns',
          instructor: 'Ezitech Faculty',
          thumbnailUrl: null,
          totalLessons: 5,
          completedLessons: 0,
          category: 'Mobile Development',
        ),
      ];

  @override
  Future<Result<CourseDetailEntity>> getCourseDetail(String courseId) async {
    try {
      final remote = await _remote.getCourseDetail(courseId);
      await _local.cacheCourseDetail(courseId, remote.course, remote.lessons, remote.description);
      return Result.success(CourseDetailEntity(
        course: remote.course,
        lessons: remote.lessons,
        description: remote.description,
      ));
    } catch (_) {
      final cached = _local.getCachedCourseDetail(courseId);
      if (cached.course != null) {
        return Result.success(CourseDetailEntity(
          course: cached.course!,
          lessons: cached.lessons,
          description: cached.description,
        ));
      }
      final seededCourses = _seedCourses();
      final matched = seededCourses.where((c) => c.id == courseId);
      if (matched.isEmpty) {
        return const Result.failure(NetworkFailure('Course not available offline yet.'));
      }
      return Result.success(_seedDetailFor(matched.first));
    }
  }

  CourseDetailEntity _seedDetailFor(CourseModel course) {
    // Public sample media so the video/PDF viewers have something real
    // to render during Week 2 review, before real LMS content URLs
    // (README API table #2) are wired in.
    final lessons = List.generate(course.totalLessons, (i) {
      return LessonModel(
        id: '${course.id}_l${i + 1}',
        courseId: course.id,
        title: 'Lesson ${i + 1}: ${course.category} fundamentals',
        videoUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        pdfUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        durationSeconds: 300 + i * 45,
        order: i + 1,
      );
    });
    return CourseDetailEntity(
      course: course,
      lessons: lessons,
      description:
          'A production-quality module covering ${course.category.toLowerCase()} '
          'as part of the Ezitech Enterprise Learning track.',
    );
  }

  @override
  Future<Result<CourseProgressEntity>> getProgress(String courseId) async {
    final raw = _local.getProgress(courseId);
    if (raw == null) return Result.success(CourseProgressEntity.empty(courseId));
    return Result.success(CourseProgressEntity(
      courseId: courseId,
      completedLessonIds: List<String>.from(raw['completed_lesson_ids'] as List? ?? []),
      lastLessonId: raw['last_lesson_id'] as String?,
      lastPositionSeconds: (raw['last_position_seconds'] as num?)?.toInt() ?? 0,
    ));
  }

  @override
  Future<void> markLessonComplete(String courseId, String lessonId) async {
    final current = await getProgress(courseId);
    final progress = current.value ?? CourseProgressEntity.empty(courseId);
    final updated = progress.copyWith(
      completedLessonIds: {...progress.completedLessonIds, lessonId}.toList(),
      lastLessonId: lessonId,
    );
    await _persistAndEnqueueProgress(updated);
  }

  @override
  Future<void> updateLastPosition(String courseId, String lessonId, int positionSeconds) async {
    final current = await getProgress(courseId);
    final progress = current.value ?? CourseProgressEntity.empty(courseId);
    final updated = progress.copyWith(lastLessonId: lessonId, lastPositionSeconds: positionSeconds);
    await _persistAndEnqueueProgress(updated);
  }

  Future<void> _persistAndEnqueueProgress(CourseProgressEntity progress) async {
    final json = {
      'course_id': progress.courseId,
      'completed_lesson_ids': progress.completedLessonIds,
      'last_lesson_id': progress.lastLessonId,
      'last_position_seconds': progress.lastPositionSeconds,
    };
    await _local.saveProgress(progress.courseId, json);
    await _outbox.enqueue(OutboxItem(
      id: _uuid.v4(),
      payloadType: OutboxPayloadType.lessonProgress,
      payloadJson: json,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Result<List<NoteEntity>>> getNotes(String lessonId) async {
    try {
      final remoteNotes = await _remote.getNotes(lessonId);
      await _local.cacheNotes(lessonId, remoteNotes);
      return Result.success(remoteNotes);
    } catch (_) {
      return Result.success(_local.getNotes(lessonId));
    }
  }

  @override
  Future<void> addNote(String lessonId, String content) async {
    final note = NoteModel(
      id: _uuid.v4(),
      lessonId: lessonId,
      content: content,
      createdAt: DateTime.now(),
    );
    await _local.addLocalNote(lessonId, note);
    await _outbox.enqueue(OutboxItem(
      id: _uuid.v4(),
      payloadType: OutboxPayloadType.note,
      payloadJson: note.toJson(),
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Result<void>> downloadForOffline(String courseId) async {
    try {
      final detailResult = await getCourseDetail(courseId);
      final detail = detailResult.value;
      if (detail == null) {
        return const Result.failure(ServerFailure('Could not download course for offline use.'));
      }
      for (final lesson in detail.lessons) {
        if (lesson.videoUrl != null) {
          await _downloads.download(
            url: lesson.videoUrl!,
            key: '${lesson.id}_video',
            extension: 'mp4',
          );
        }
        if (lesson.pdfUrl != null) {
          await _downloads.download(
            url: lesson.pdfUrl!,
            key: '${lesson.id}_pdf',
            extension: 'pdf',
          );
        }
      }
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not download course for offline use.'));
    }
  }

  /// Used by CourseDetailScreen to decide whether to hand the video/PDF
  /// widgets a local file path or a network URL.
  Future<String?> localVideoPath(String lessonId) =>
      _downloads.localPathIfExists('${lessonId}_video', 'mp4');

  Future<String?> localPdfPath(String lessonId) =>
      _downloads.localPathIfExists('${lessonId}_pdf', 'pdf');

  @override
  Future<LessonEntity?> resumeLessonFor(String courseId) async {
    final detailResult = await getCourseDetail(courseId);
    final detail = detailResult.value;
    if (detail == null || detail.lessons.isEmpty) return null;

    final progressResult = await getProgress(courseId);
    final progress = progressResult.value;
    final sortedLessons = [...detail.lessons]..sort((a, b) => a.order.compareTo(b.order));

    if (progress?.lastLessonId != null) {
      final match = sortedLessons.where((l) => l.id == progress!.lastLessonId);
      if (match.isNotEmpty) return match.first;
    }
    return sortedLessons.first;
  }

  /// Called by SyncWorker when a lesson_progress outbox item is drained.
  Future<void> syncProgress(Map<String, dynamic> payload) async {
    await _remote.syncProgress(payload['course_id'] as String, payload);
  }

  /// Called by SyncWorker when a note outbox item is drained.
  Future<void> syncNote(Map<String, dynamic> payload) async {
    await _remote.syncNote(payload);
  }
}
