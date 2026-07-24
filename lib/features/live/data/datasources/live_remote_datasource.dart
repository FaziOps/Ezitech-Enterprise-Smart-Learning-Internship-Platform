import '../../../../core/network/api_client.dart';
import '../models/live_session_model.dart';

/// README API table entry #6 (Live Session / Video Conferencing API) —
/// which provider Ezitech uses (Zoom, Jitsi, Agora, a plain scheduling
/// link) determines whether [LiveSessionModel.joinUrl] opens an external
/// app via url_launcher (current implementation) or needs an embedded SDK.
class LiveRemoteDataSource {
  const LiveRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LiveSessionModel>> getSchedule() async {
    final response = await _apiClient.dio.get(ApiConfig.liveSessions);
    final list = response.data as List;
    return list.map((e) => LiveSessionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> syncAttendance(Map<String, dynamic> payload) async {
    await _apiClient.dio.post(
      '${ApiConfig.liveSessions}/${payload['session_id']}/attendance',
      data: payload,
    );
  }
}
