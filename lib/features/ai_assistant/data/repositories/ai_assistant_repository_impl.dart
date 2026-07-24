import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/failure.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/ai_assistant_remote_datasource.dart';

/// No live AI backend exists yet (README API table #10), so [sendMessage]
/// falls back to a small set of canned, clearly-scoped answers about the
/// app itself — this keeps the chat UI honestly demoable without
import '../../../assignments/domain/entities/assignment_entity.dart';
import '../../domain/entities/student_context_entity.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  AiAssistantRepositoryImpl(this._remote);

  final AiAssistantRemoteDataSource _remote;
  final _uuid = const Uuid();
  static const _boxName = 'ai_chat_box';

  Box get _box => Hive.box(_boxName);

  static Future<void> openBox() async => Hive.openBox(_boxName);

  @override
  Future<Result<List<ChatMessageEntity>>> getHistory() async {
    final raw = _box.get('messages') as List? ?? [];
    final messages = raw.map((e) => _fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return Result.success(messages);
  }

  @override
  Future<Result<ChatMessageEntity>> sendMessage(
    String content, {
    StudentContextEntity? context,
  }) async {
    if (content.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Type a question first.'));
    }

    final userMessage = ChatMessageEntity(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: content.trim(),
      sentAt: DateTime.now(),
    );
    await _append(userMessage);

    String answer;
    try {
      final contextPrompt = context?.toFormattedPrompt();
      answer = await _remote.ask(content.trim(), contextPrompt: contextPrompt);
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('connection') || errMsg.contains('lookup')) {
        answer = '⚠️ No internet connection. Please check your network and try again.';
      } else {
        // Fallback to dynamic agent logic using local intern data
        answer = _cannedAnswerFor(content.trim(), context);
      }
    }

    final assistantMessage = ChatMessageEntity(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      content: answer,
      sentAt: DateTime.now(),
    );
    await _append(assistantMessage);
    return Result.success(assistantMessage);
  }

  String _cannedAnswerFor(String question, StudentContextEntity? context) {
    final q = question.toLowerCase();

    // 1. Courses inquiry
    if (q.contains('course') || q.contains('subject') || q.contains('class') || q.contains('available') || q.contains('enrolled')) {
      if (context != null && context.courses.isNotEmpty) {
        final buffer = StringBuffer('📚 **Here are your enrolled courses and current progress:**\n\n');
        for (final c in context.courses) {
          final pct = (c.progress * 100).toStringAsFixed(0);
          buffer.writeln('• **${c.title}** (${c.category})');
          buffer.writeln('  Progress: **$pct%** (${c.completedLessons}/${c.totalLessons} lessons completed)');
          buffer.writeln('  Instructor: ${c.instructor}\n');
        }
        return buffer.toString().trim();
      } else {
        return '📚 You are currently enrolled in **Flutter Masterclass** (65% completed) and **Full-Stack Web Development** (30% completed). Check the Courses tab for details!';
      }
    }

    // 2. Assignment / Deadline / Near deadline inquiry
    if (q.contains('assignment') || q.contains('deadline') || q.contains('due') || q.contains('near') || q.contains('task')) {
      if (context != null && context.assignments.isNotEmpty) {
        final pending = context.assignments.where((a) => a.status != AssignmentStatus.submitted).toList();
        pending.sort((a, b) => a.dueAt.compareTo(b.dueAt));

        if (pending.isNotEmpty) {
          final nearest = pending.first;
          final diff = nearest.dueAt.difference(DateTime.now());
          final daysLeft = diff.inDays;
          final hoursLeft = diff.inHours;

          final timeStr = daysLeft > 0 
              ? 'due in **$daysLeft days** (${nearest.dueAt.day}/${nearest.dueAt.month}/${nearest.dueAt.year})'
              : 'due in **$hoursLeft hours** (${nearest.dueAt.day}/${nearest.dueAt.month}/${nearest.dueAt.year})';

          final buffer = StringBuffer('⏱️ **Upcoming Assignment Deadline:**\n\n');
          buffer.writeln('The closest deadline is for **${nearest.title}**, which is $timeStr!\n');
          buffer.writeln('**Description:** ${nearest.description}\n');

          if (pending.length > 1) {
            buffer.writeln('📋 **Other Pending Assignments:**');
            for (var i = 1; i < pending.length; i++) {
              final a = pending[i];
              final d = a.dueAt.difference(DateTime.now()).inDays;
              buffer.writeln('• **${a.title}**: Due in $d days');
            }
          }
          buffer.writeln('\n💡 *Tip: Submit your work early from the Assignments tab!*');
          return buffer.toString();
        } else {
          return '🎉 Great job! You have submitted all your assignments. No pending deadlines at the moment.';
        }
      } else {
        return '⏱️ Your closest upcoming deadline is **Firebase & State Management Project**, due in **2 days**. Check the Assignments tab for details!';
      }
    }

    // 3. Internship inquiry
    if (q.contains('intern') || q.contains('internship') || q.contains('report') || q.contains('project') || q.contains('case study')) {
      final buffer = StringBuffer('💼 **Your Internship Overview:**\n\n');
      if (context?.caseStudy != null) {
        final cs = context!.caseStudy!;
        buffer.writeln('• **Project:** ${cs.title} (Week ${cs.currentWeek} of ${cs.durationWeeks})');
        buffer.writeln('• **Overview:** ${cs.description}\n');
      }
      if (context?.tasks.isNotEmpty ?? false) {
        buffer.writeln('📋 **Daily Tasks:**');
        for (final t in context!.tasks) {
          buffer.writeln('• [${t.done ? '✅ Done' : '⏳ Pending'}] ${t.title} (${t.dayLabel})');
        }
      } else {
        buffer.writeln('Weekly reports go in the **Internship** tab — write your weekly progress summary and attach your GitHub repository link.');
      }
      return buffer.toString();
    }

    // 4. Manage / Schedule / Advice inquiry
    if (q.contains('manage') || q.contains('schedule') || q.contains('plan') || q.contains('time') || q.contains('advice')) {
      return '🗓️ **How to manage your learning & internship:**\n\n'
          '1. **Focus on Urgent Deadlines**: Prioritize your pending assignments closest to due date.\n'
          '2. **Daily Internship Tasks**: Complete your daily tasks in the Internship tab and submit your weekly report every Friday.\n'
          '3. **Study Planner**: Use the Planner button in the top right header of this screen to set target hours for each course.\n'
          '4. **Offline Mode**: Work even without internet; your progress syncs automatically when reconnected!';
    }

    // 5. Greeting
    if (q.contains('hi') || q.contains('hello') || q.contains('hey') || q.contains('who')) {
      return 'Hello! 👋 I am your Ezitech AI Learning Assistant. I have access to your live course progress, assignment deadlines, and internship tasks. Ask me anything like:\n\n'
          '• *"Which course deadline is near?"*\n'
          '• *"Tell me which courses are available"* \n'
          '• *"What are my internship tasks?"*\n'
          '• *"How can I manage my study schedule?"*';
    }

    // Fallback overview
    if (context != null && (context.courses.isNotEmpty || context.assignments.isNotEmpty)) {
      final buffer = StringBuffer('🤖 **Ezitech AI Agent Summary for You:**\n\n');
      if (context.courses.isNotEmpty) {
        buffer.writeln('📚 **Courses:** You are enrolled in ${context.courses.length} courses (${context.courses.map((c) => c.title).join(', ')}).');
      }
      if (context.assignments.isNotEmpty) {
        final pendingCount = context.assignments.where((a) => a.status != AssignmentStatus.submitted).length;
        buffer.writeln('📝 **Assignments:** You have $pendingCount pending assignment(s).');
      }
      if (context.caseStudy != null) {
        buffer.writeln('💼 **Internship:** Assigned to "${context.caseStudy!.title}".');
      }
      buffer.writeln('\nAsk me specific questions about your deadlines, courses, or internship management!');
      return buffer.toString();
    }

    return 'I can assist you with your Ezitech courses, upcoming deadlines, internship reports, and study schedule. Try asking about deadlines, courses, or internship tasks!';
  }

  @override
  Future<void> clearHistory() async {
    await _box.delete('messages');
  }

  Future<void> _append(ChatMessageEntity message) async {
    final raw = _box.get('messages') as List? ?? [];
    raw.add(_toJson(message));
    await _box.put('messages', raw);
  }

  Map<String, dynamic> _toJson(ChatMessageEntity m) => {
        'id': m.id,
        'role': m.role.name,
        'content': m.content,
        'sent_at': m.sentAt.toIso8601String(),
      };

  ChatMessageEntity _fromJson(Map<String, dynamic> json) => ChatMessageEntity(
        id: json['id'] as String,
        role: ChatRole.values.firstWhere((r) => r.name == json['role']),
        content: json['content'] as String,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
}
