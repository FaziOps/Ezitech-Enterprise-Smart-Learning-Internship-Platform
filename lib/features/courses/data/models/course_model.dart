import '../../domain/entities/course_entity.dart';

class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    required super.title,
    required super.instructor,
    required super.thumbnailUrl,
    required super.totalLessons,
    required super.completedLessons,
    required super.category,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String,
        title: json['title'] as String,
        instructor: json['instructor'] as String? ?? 'Ezitech Faculty',
        thumbnailUrl: json['thumbnail_url'] as String?,
        totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
        completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
        category: json['category'] as String? ?? 'General',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'instructor': instructor,
        'thumbnail_url': thumbnailUrl,
        'total_lessons': totalLessons,
        'completed_lessons': completedLessons,
        'category': category,
      };
}

class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.courseId,
    required super.title,
    required super.videoUrl,
    required super.pdfUrl,
    required super.durationSeconds,
    required super.order,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json['id'] as String,
        courseId: json['course_id'] as String,
        title: json['title'] as String,
        videoUrl: json['video_url'] as String?,
        pdfUrl: json['pdf_url'] as String?,
        durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'video_url': videoUrl,
        'pdf_url': pdfUrl,
        'duration_seconds': durationSeconds,
        'order': order,
      };
}

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.lessonId,
    required super.content,
    required super.createdAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] as String,
        lessonId: json['lesson_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
