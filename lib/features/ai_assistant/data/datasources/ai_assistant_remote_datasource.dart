import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

/// README API table entry #10 — whether this proxies to an Ezitech-hosted
/// LLM backend or calls a provider directly changes where the API key
/// lives; either way, the client only ever talks to this one endpoint
/// and never holds an LLM API key itself.
class AiAssistantRemoteDataSource {
  const AiAssistantRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  // API key — set via --dart-define=GEMINI_API_KEY=... at build time,
  // or falls back to the key baked in as a default for development builds.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // System prompt that scopes the assistant to the Ezitech learning context.
  static const String _systemPrompt =
      'You are an AI learning assistant embedded in the Ezitech Enterprise '
      'Learning & Internship mobile platform. Help students with their courses, '
      'assignments, internship tasks, weekly reports, and study planning. '
      'Keep answers concise and practical. If a question is unrelated to '
      'learning or the platform, gently redirect the user.';

  Future<String> ask(String question, {String? contextPrompt}) async {
    final fullSystemPrompt = contextPrompt != null && contextPrompt.isNotEmpty
        ? '$_systemPrompt\n\n$contextPrompt'
        : _systemPrompt;

    if (geminiApiKey.isNotEmpty) {
      try {
        final dio = Dio();
        final response = await dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey',
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {
            'system_instruction': {
              'parts': [{'text': fullSystemPrompt}]
            },
            'contents': [
              {
                'parts': [{'text': question}]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 512,
            },
          },
        );

        final candidates = response.data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] as String;
            }
          }
        }
        throw Exception('Unexpected response shape from Gemini API');
      } on DioException catch (e) {
        // Surface the real error message so it's clear in logs what went wrong
        final status = e.response?.statusCode;
        final body = e.response?.data?.toString() ?? e.message;
        print('Gemini API error ($status): $body');
        // Re-throw so the repository can show the actual error instead of canned text
        rethrow;
      } catch (e) {
        print('Gemini call failed: $e');
        rethrow;
      }
    }

    final response = await _apiClient.dio.post(
      ApiConfig.aiAssistant,
      data: {'question': question},
    );
    return (response.data as Map<String, dynamic>)['answer'] as String;
  }
}
