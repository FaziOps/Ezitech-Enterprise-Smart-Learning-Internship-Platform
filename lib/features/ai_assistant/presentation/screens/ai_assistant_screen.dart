import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../assignments/presentation/providers/assignment_providers.dart';
import '../../../courses/presentation/providers/course_providers.dart';
import '../../../internship/presentation/providers/internship_providers.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/student_context_entity.dart';
import '../providers/ai_assistant_providers.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.medium,
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final courses = ref.read(coursesListProvider).valueOrNull ?? [];
    final assignments = ref.read(assignmentsListProvider).valueOrNull ?? [];
    final caseStudy = ref.read(caseStudyProvider).valueOrNull;
    final tasks = ref.read(internshipTasksProvider).valueOrNull ?? [];

    final studentContext = StudentContextEntity(
      courses: courses,
      assignments: assignments,
      caseStudy: caseStudy,
      tasks: tasks,
    );

    await ref.read(chatControllerProvider.notifier).send(text, context: studentContext);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: AppColors.aiAccent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('AI Learning Assistant', style: Theme.of(context).textTheme.headlineSmall),
              ),
              GestureDetector(
                onTap: () => context.push('/ai-assistant/study-planner'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.aiAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.aiAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.aiAccent),
                      SizedBox(width: 4),
                      Text('Planner', style: TextStyle(fontSize: 12, color: AppColors.aiAccent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                tooltip: 'Clear chat history',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear chat?'),
                      content: const Text('This will delete all messages in this conversation.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(chatControllerProvider.notifier).clear();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: chatState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Could not load chat: $e')),
            data: (messages) {
              if (messages.isEmpty) return _EmptyState(onSuggestionTap: (q) {
                _controller.text = q;
                _send();
              });
              _scrollToBottom();
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: messages.length,
                itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + 80),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question…',
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  tooltip: 'Send message',
                  icon: const Icon(Icons.send, color: AppColors.aiAccent),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestionTap});
  final ValueChanged<String> onSuggestionTap;

  static const _suggestions = [
    'How does offline sync work?',
    'Where do I submit my weekly report?',
    'What deadlines are coming up?',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_outlined, color: AppColors.aiAccent, size: 40),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Ask me anything about your courses, deadlines, or internship.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final s in _suggestions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GlassCard(
                onTap: () => onSuggestionTap(s),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Text(s, style: const TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          fillColor: isUser ? AppColors.glassFillStrong : AppColors.glassFillLight,
          child: Text(message.content),
        ),
      ),
    );
  }
}
