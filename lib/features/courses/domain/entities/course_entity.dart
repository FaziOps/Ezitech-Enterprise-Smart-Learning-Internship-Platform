import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  const CourseEntity({
    required this.id,
    required this.title,
    required this.instructor,
    required this.thumbnailUrl,
    required this.totalLessons,
    required this.completedLessons,
    required this.category,
  });

  final String id;
  final String title;
  final String instructor;
  final String? thumbnailUrl;
  final int totalLessons;
  final int completedLessons;
  final String category;

  double get progress => totalLessons == 0 ? 0 : completedLessons / totalLessons;

  @override
  List<Object?> get props =>
      [id, title, instructor, thumbnailUrl, totalLessons, completedLessons, category];
}

class LessonEntity extends Equatable {
  const LessonEntity({
    required this.id,
    required this.courseId,
    required this.title,
    required this.videoUrl,
    required this.pdfUrl,
    required this.durationSeconds,
    required this.order,
  });

  final String id;
  final String courseId;
  final String title;
  final String? videoUrl;
  final String? pdfUrl;
  final int durationSeconds;
  final int order;

  @override
  List<Object?> get props =>
      [id, courseId, title, videoUrl, pdfUrl, durationSeconds, order];
}

class CourseDetailEntity extends Equatable {
  const CourseDetailEntity({
    required this.course,
    required this.lessons,
    required this.description,
  });

  final CourseEntity course;
  final List<LessonEntity> lessons;
  final String description;

  @override
  List<Object?> get props => [course, lessons, description];
}

/// Tracks per-lesson video position (for "Smart Video Resume" — bonus
/// challenge, architected for now) and per-course completion state.
class CourseProgressEntity extends Equatable {
  const CourseProgressEntity({
    required this.courseId,
    required this.completedLessonIds,
    required this.lastLessonId,
    required this.lastPositionSeconds,
  });

  final String courseId;
  final List<String> completedLessonIds;
  final String? lastLessonId;
  final int lastPositionSeconds;

  static CourseProgressEntity empty(String courseId) => CourseProgressEntity(
        courseId: courseId,
        completedLessonIds: const [],
        lastLessonId: null,
        lastPositionSeconds: 0,
      );

  CourseProgressEntity copyWith({
    List<String>? completedLessonIds,
    String? lastLessonId,
    int? lastPositionSeconds,
  }) {
    return CourseProgressEntity(
      courseId: courseId,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      lastLessonId: lastLessonId ?? this.lastLessonId,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
    );
  }

  @override
  List<Object?> get props =>
      [courseId, completedLessonIds, lastLessonId, lastPositionSeconds];
}

class NoteEntity extends Equatable {
  const NoteEntity({
    required this.id,
    required this.lessonId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String lessonId;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, lessonId, content, createdAt];
}
