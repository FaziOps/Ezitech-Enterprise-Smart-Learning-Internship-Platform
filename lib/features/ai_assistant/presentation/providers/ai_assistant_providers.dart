import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/ai_assistant_remote_datasource.dart';
import '../../data/repositories/ai_assistant_repository_impl.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/student_context_entity.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

final aiRemoteDataSourceProvider =
    Provider((ref) => AiAssistantRemoteDataSource(ref.watch(apiClientProvider)));

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>(
  (ref) => AiAssistantRepositoryImpl(ref.watch(aiRemoteDataSourceProvider)),
);

/// StateNotifier rather than a plain FutureProvider because chat history
/// needs to append optimistically as messages send, not just re-fetch —
/// a FutureProvider re-read would flicker the whole list on every send.
class ChatController extends StateNotifier<AsyncValue<List<ChatMessageEntity>>> {
  ChatController(this._repository) : super(const AsyncValue.loading()) {
    _loadHistory();
  }

  final AiAssistantRepository _repository;
  bool sending = false;

  Future<void> _loadHistory() async {
    final result = await _repository.getHistory();
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (messages) => AsyncValue.data(messages),
    );
  }

  Future<void> send(String content, {StudentContextEntity? context}) async {
    if (sending) return;
    sending = true;
    final result = await _repository.sendMessage(content, context: context);
    sending = false;
    result.fold(
      (failure) {}, // validation failures (empty message) are silently ignored by the UI's own guard
      (_) => _loadHistory(),
    );
  }

  Future<void> clear() async {
    await _repository.clearHistory();
    state = const AsyncValue.data([]);
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, AsyncValue<List<ChatMessageEntity>>>(
  (ref) => ChatController(ref.watch(aiAssistantRepositoryProvider)),
);
