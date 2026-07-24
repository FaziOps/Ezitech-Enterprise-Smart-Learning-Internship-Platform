import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/assignment_model.dart';

/// Talks to the Assignment Management API — README table entry #4.
class AssignmentRemoteDataSource {
  const AssignmentRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AssignmentModel>> getAssignments() async {
    final response = await _apiClient.dio.get(ApiConfig.assignments);
    final list = response.data as List;
    return list.map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AssignmentModel> getAssignmentDetail(String assignmentId) async {
    final response = await _apiClient.dio.get('${ApiConfig.assignments}/$assignmentId');
    return AssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Called by the sync worker once connectivity is available. Uploads
  /// the file (if any) as multipart/form-data alongside the optional
  /// GitHub link — matches the "File Upload + GitHub Submission" pair
  /// from the case study's Assignment Management module.
  Future<void> submitAssignment(Map<String, dynamic> payload) async {
    final formMap = <String, dynamic>{
      'assignment_id': payload['assignment_id'],
      if (payload['github_link'] != null) 'github_link': payload['github_link'],
    };
    final filePath = payload['file_path'] as String?;
    if (filePath != null && filePath.isNotEmpty) {
      formMap['file'] = await MultipartFile.fromFile(filePath);
    }
    final formData = FormData.fromMap(formMap);
    await _apiClient.dio.post(
      '${ApiConfig.assignments}/${payload['assignment_id']}/submit',
      data: formData,
    );
  }
}
