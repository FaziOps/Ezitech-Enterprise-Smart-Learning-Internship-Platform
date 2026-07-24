import '../../../../core/utils/failure.dart';
import '../entities/chat_message_entity.dart';
import '../entities/student_context_entity.dart';

abstract class AiAssistantRepository {
  Future<Result<List<ChatMessageEntity>>> getHistory();
  Future<Result<ChatMessageEntity>> sendMessage(String content, {StudentContextEntity? context});
  Future<void> clearHistory();
}
