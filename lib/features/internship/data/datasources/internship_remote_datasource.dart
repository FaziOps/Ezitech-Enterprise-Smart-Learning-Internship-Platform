import '../../../../core/network/api_client.dart';
import '../models/internship_model.dart';

/// Talks to the Internship Portal API — see README API table entry #3.
class InternshipRemoteDataSource {
  const InternshipRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CaseStudyModel> getAssignedCaseStudy() async {
    final response = await _apiClient.dio.get('${ApiConfig.internship}/case-study');
    return CaseStudyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<InternshipTaskModel>> getDailyTasks() async {
    final response = await _apiClient.dio.get('${ApiConfig.internship}/tasks');
    final list = response.data as List;
    return list.map((e) => InternshipTaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> syncTaskState(Map<String, dynamic> payload) async {
    await _apiClient.dio.patch(
      '${ApiConfig.internship}/tasks/${payload['id']}',
      data: {'done': payload['done']},
    );
  }

  Future<List<MentorFeedbackModel>> getMentorFeedback() async {
    final response = await _apiClient.dio.get('${ApiConfig.internship}/feedback');
    final list = response.data as List;
    return list.map((e) => MentorFeedbackModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> syncWeeklyReport(Map<String, dynamic> payload) async {
    await _apiClient.dio.post('${ApiConfig.internship}/reports', data: payload);
  }
}
