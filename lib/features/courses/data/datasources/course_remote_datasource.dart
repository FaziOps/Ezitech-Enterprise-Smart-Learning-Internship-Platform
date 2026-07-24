import '../../../../core/network/api_client.dart';
import '../models/course_model.dart';

/// Talks to the Ezitech LMS API. Real responses should match the shapes
/// in [CourseModel]/[LessonModel]/[NoteModel] — see README API table
/// entry #2. Until that endpoint exists, [getCourses]/[getCourseDetail]
/// are called by the repository behind a try/catch that falls back to
/// cached or seeded data (see CourseRepositoryImpl), so the UI is
/// exercised end-to-end even without a live backend.
class CourseRemoteDataSource {
  const CourseRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CourseModel>> getCourses() async {
    final response = await _apiClient.dio.get(ApiConfig.courses);
    final list = response.data as List;
    return list.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({CourseModel course, List<LessonModel> lessons, String description})> getCourseDetail(
    String courseId,
  ) async {
    final response = await _apiClient.dio.get('${ApiConfig.courses}/$courseId');
    final data = response.data as Map<String, dynamic>;
    return (
      course: CourseModel.fromJson(data['course'] as Map<String, dynamic>),
      lessons: (data['lessons'] as List)
          .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: data['description'] as String? ?? '',
    );
  }

  Future<void> syncProgress(String courseId, Map<String, dynamic> progressJson) async {
    await _apiClient.dio.post('${ApiConfig.courses}/$courseId/progress', data: progressJson);
  }

  Future<List<NoteModel>> getNotes(String lessonId) async {
    final response = await _apiClient.dio.get('${ApiConfig.courses}/lessons/$lessonId/notes');
    final list = response.data as List;
    return list.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> syncNote(Map<String, dynamic> noteJson) async {
    await _apiClient.dio.post(
      '${ApiConfig.courses}/lessons/${noteJson['lesson_id']}/notes',
      data: noteJson,
    );
  }
}
