import '../../../../core/network/api_client.dart';
import '../models/portfolio_model.dart';

/// README API table entry #11 — likely the same LMS API as Course
/// Management, but treated as its own endpoint here since certificates/
/// projects/skills may be assembled server-side from multiple sources.
class PortfolioRemoteDataSource {
  const PortfolioRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<PortfolioModel> getPortfolio() async {
    final response = await _apiClient.dio.get(ApiConfig.portfolio);
    return PortfolioModel.fromJson(response.data as Map<String, dynamic>);
  }
}
