import 'package:hive/hive.dart';
import '../models/course_model.dart';

/// Plain dynamic Hive boxes (no typed adapter needed — everything here
/// is stored as JSON-shaped maps) holding the last-known-good copy of
/// courses, lessons, progress, and notes. This is what makes the app
/// "offline-first" for reads: the UI always renders from here first,
/// and a network refresh (when available) just overwrites these boxes.
class CourseLocalDataSource {
  static const coursesBox = 'courses_cache_box';
  static const lessonsBox = 'lessons_cache_box';
  static const progressBox = 'course_progress_box';
  static const notesBox = 'notes_cache_box';

  static Future<void> openBoxes() async {
    await Hive.openBox(coursesBox);
    await Hive.openBox(lessonsBox);
    await Hive.openBox(progressBox);
    await Hive.openBox(notesBox);
  }

  Box get _courses => Hive.box(coursesBox);
  Box get _lessons => Hive.box(lessonsBox);
  Box get _progress => Hive.box(progressBox);
  Box get _notes => Hive.box(notesBox);

  Future<void> cacheCourses(List<CourseModel> courses) async {
    await _courses.put('all', courses.map((c) => c.toJson()).toList());
  }

  List<CourseModel>? getCachedCourses() {
    final raw = _courses.get('all') as List?;
    if (raw == null) return null;
    return raw
        .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> cacheCourseDetail(String courseId, CourseModel course, List<LessonModel> lessons, String description) async {
    await _courses.put(courseId, course.toJson());
    await _lessons.put(courseId, lessons.map((l) => l.toJson()).toList());
    await _courses.put('${courseId}_description', description);
  }

  ({CourseModel? course, List<LessonModel> lessons, String description}) getCachedCourseDetail(
    String courseId,
  ) {
    final courseJson = _courses.get(courseId) as Map?;
    final lessonsRaw = _lessons.get(courseId) as List?;
    final description = _courses.get('${courseId}_description') as String? ?? '';
    return (
      course: courseJson == null
          ? null
          : CourseModel.fromJson(Map<String, dynamic>.from(courseJson)),
      lessons: (lessonsRaw ?? [])
          .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      description: description,
    );
  }

  Future<void> saveProgress(String courseId, Map<String, dynamic> progressJson) async {
    await _progress.put(courseId, progressJson);
  }

  Map<String, dynamic>? getProgress(String courseId) {
    final raw = _progress.get(courseId) as Map?;
    return raw == null ? null : Map<String, dynamic>.from(raw);
  }

  Future<void> cacheNotes(String lessonId, List<NoteModel> notes) async {
    await _notes.put(lessonId, notes.map((n) => n.toJson()).toList());
  }

  Future<void> addLocalNote(String lessonId, NoteModel note) async {
    final existing = _notes.get(lessonId) as List? ?? [];
    existing.add(note.toJson());
    await _notes.put(lessonId, existing);
  }

  List<NoteModel> getNotes(String lessonId) {
    final raw = _notes.get(lessonId) as List? ?? [];
    return raw.map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
