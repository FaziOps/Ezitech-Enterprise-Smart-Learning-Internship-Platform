import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../storage/secure_storage_service.dart';

/// Base URL and endpoint map live here so the whole app has one place to
/// point at staging vs production vs a local mock server.
///
/// IMPORTANT: replace [baseUrl] with the real Ezitech Gateway URL once
/// it's provided. Every module (Courses, Internship, Assignments, Live
/// Learning, AI Assistant) talks through this single Dio instance so auth
/// headers and token refresh are handled in exactly one place.
class ApiConfig {
  ApiConfig._();
  static const String baseUrl = String.fromEnvironment(
    'EZITECH_API_BASE_URL',
    defaultValue: 'https://api.ezitech.example.com/v1',
  );

  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String sessions = '/auth/sessions';

  static const String dashboard = '/dashboard';
  static const String courses = '/courses';
  static const String internship = '/internship';
  static const String assignments = '/assignments';
  static const String liveSessions = '/live-sessions';
  static const String portfolio = '/portfolio';
  static const String aiAssistant = '/ai/assistant';
  static const String notifications = '/notifications';
  static const String githubSubmit = '/integrations/github/submit';
}

class ApiClient {
  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    ]);
  }

  late final Dio _dio;
  final SecureStorageService _secureStorage;

  Dio get dio => _dio;

  /// Attaches the access token to every request and transparently retries
  /// once with a refreshed token on a 401 — the offline outbox worker and
  /// every repository rely on this so they never have to think about
  /// token expiry themselves.
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (isUnauthorized && !alreadyRetried) {
          final refreshToken = await _secureStorage.readRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshResponse = await _dio.post(
                ApiConfig.refresh,
                data: {'refresh_token': refreshToken},
              );
              final newAccessToken = refreshResponse.data['access_token'] as String;
              await _secureStorage.writeAccessToken(newAccessToken);

              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              retryOptions.extra['retried'] = true;

              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              await _secureStorage.clearAll();
              // Falls through to handler.next below; router's redirect
              // logic (see core/router/app_router.dart) sends the user
              // back to login when the session state clears.
            }
          }
        }
        handler.next(error);
      },
    );
  }
}
