import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/live_session_entity.dart';
import '../providers/live_providers.dart';

/// A simple in-memory chat message for the live session.
class _ChatMessage {
  _ChatMessage({required this.author, required this.text, required this.isMe});
  final String author;
  final String text;
  final bool isMe;
  final DateTime time = DateTime.now();
}

/// Provider that holds the list of chat messages for a given session ID.
/// In production this would be backed by Socket.IO — the socket_io_client
/// package is already in pubspec.yaml for when the backend is ready.
final _liveChatProvider = StateProvider.family<List<_ChatMessage>, String>(
  (ref, sessionId) => [
    _ChatMessage(author: 'Ayesha Raza', text: 'Welcome everyone! We\'ll start in 2 minutes.', isMe: false),
    _ChatMessage(author: 'Hassan Ali', text: 'Ready! 🙌', isMe: false),
    _ChatMessage(author: 'You', text: 'Joined, sound is clear.', isMe: true),
  ],
);

class LiveSessionChatScreen extends ConsumerStatefulWidget {
  const LiveSessionChatScreen({super.key, required this.session});
  final LiveSessionEntity session;

  @override
  ConsumerState<LiveSessionChatScreen> createState() => _LiveSessionChatScreenState();
}

class _LiveSessionChatScreenState extends ConsumerState<LiveSessionChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    ref.read(_liveChatProvider(widget.session.id).notifier).update(
          (msgs) => [...msgs, _ChatMessage(author: 'You', text: text, isMe: true)],
        );
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: AppMotion.medium,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(_liveChatProvider(widget.session.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Live Chat', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          // Live indicator
          if (widget.session.state == LiveSessionState.live)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.danger),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('LIVE', style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Session info banner
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('Host: ${widget.session.hostName}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Spacer(),
                  const Icon(Icons.schedule_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${widget.session.durationMinutes} min', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: messages.length,
              itemBuilder: (context, i) => _ChatBubble(message: messages[i]),
            ),
          ),
          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md + 80),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Message the class…',
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send message',
                    icon: const Icon(Icons.send, color: AppColors.danger),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!message.isMe)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 2),
                child: Text(
                  message.author,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            GlassContainer(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              fillColor: message.isMe ? AppColors.primary.withOpacity(0.2) : AppColors.glassFillLight,
              borderColor: message.isMe ? AppColors.primary.withOpacity(0.4) : AppColors.glassBorder,
              child: Text(message.text, style: const TextStyle(fontSize: 13)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: AppColors.textDisabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
