import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.sentAt,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime sentAt;

  @override
  List<Object?> get props => [id, role, content, sentAt];
}
