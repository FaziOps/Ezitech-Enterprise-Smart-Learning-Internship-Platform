import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/course_providers.dart';
import '../widgets/pdf_reader_section.dart';
import '../widgets/video_player_section.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  LessonEntity? _selectedLesson;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(courseDetailProvider(widget.courseId));
    final progressAsync = ref.watch(courseProgressProvider(widget.courseId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Course'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load course: $err')),
        data: (detail) {
          final progress = progressAsync.valueOrNull ?? CourseProgressEntity.empty(widget.courseId);
          _selectedLesson ??= _resolveInitialLesson(detail, progress);

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
            children: [
              Text(detail.course.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail.description,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_selectedLesson != null) ...[
                Consumer(
                  builder: (context, ref, _) {
                    final localVideo = ref.watch(localVideoPathProvider(_selectedLesson!.id));
                    return VideoPlayerSection(
                      key: ValueKey(_selectedLesson!.id),
                      videoUrl: _selectedLesson!.videoUrl!,
                      localFilePath: localVideo.valueOrNull,
                      startPositionSeconds: progress.lastLessonId == _selectedLesson!.id
                          ? progress.lastPositionSeconds
                          : 0,
                      onPositionChanged: (seconds) => ref
                          .read(courseRepositoryProvider)
                          .updateLastPosition(widget.courseId, _selectedLesson!.id, seconds),
                      onCompleted: () {
                        ref
                            .read(courseRepositoryProvider)
                            .markLessonComplete(widget.courseId, _selectedLesson!.id);
                        ref.invalidate(courseProgressProvider(widget.courseId));
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (_selectedLesson!.pdfUrl != null) ...[
                  Text('Lesson notes (PDF)', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer(
                    builder: (context, ref, _) {
                      final localPdf = ref.watch(localPdfPathProvider(_selectedLesson!.id));
                      return PdfReaderSection(
                        pdfUrl: _selectedLesson!.pdfUrl!,
                        localFilePath: localPdf.valueOrNull,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
              _LessonListCard(
                lessons: detail.lessons,
                completedIds: progress.completedLessonIds,
                selectedId: _selectedLesson?.id,
                onSelect: (lesson) => setState(() => _selectedLesson = lesson),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_selectedLesson != null) _NotesCard(lessonId: _selectedLesson!.id),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result =
                        await ref.read(courseRepositoryProvider).downloadForOffline(widget.courseId);
                    if (result.isSuccess && _selectedLesson != null) {
                      ref.invalidate(localVideoPathProvider(_selectedLesson!.id));
                      ref.invalidate(localPdfPathProvider(_selectedLesson!.id));
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.isSuccess
                              ? 'Course cached for offline viewing.'
                              : 'Could not download: ${result.failure?.message}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download for Offline'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  LessonEntity? _resolveInitialLesson(CourseDetailEntity detail, CourseProgressEntity progress) {
    if (detail.lessons.isEmpty) return null;
    final sorted = [...detail.lessons]..sort((a, b) => a.order.compareTo(b.order));
    if (progress.lastLessonId != null) {
      final match = sorted.where((l) => l.id == progress.lastLessonId);
      if (match.isNotEmpty) return match.first;
    }
    return sorted.first;
  }
}

class _LessonListCard extends StatelessWidget {
  const _LessonListCard({
    required this.lessons,
    required this.completedIds,
    required this.selectedId,
    required this.onSelect,
  });

  final List<LessonEntity> lessons;
  final List<String> completedIds;
  final String? selectedId;
  final ValueChanged<LessonEntity> onSelect;

  @override
  Widget build(BuildContext context) {
    final sorted = [...lessons]..sort((a, b) => a.order.compareTo(b.order));
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lessons', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final lesson in sorted)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => onSelect(lesson),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: lesson.id == selectedId ? AppColors.glassFillStrong : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      completedIds.contains(lesson.id)
                          ? Icons.check_circle
                          : Icons.play_circle_outline,
                      size: 18,
                      color: completedIds.contains(lesson.id)
                          ? AppColors.secondary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(lesson.title, overflow: TextOverflow.ellipsis)),
                    Text(
                      '${(lesson.durationSeconds / 60).round()} min',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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

class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard({required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(lessonNotesProvider(widget.lessonId));

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          notesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const Text('Could not load notes.'),
            data: (notes) => notes.isEmpty
                ? const Text('No notes yet.', style: TextStyle(color: AppColors.textMuted))
                : Column(
                    children: [
                      for (final n in notes)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('• ${n.content}'),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Add a note…'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Add note',
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: () async {
                  if (_controller.text.trim().isEmpty) return;
                  await ref
                      .read(courseRepositoryProvider)
                      .addNote(widget.lessonId, _controller.text.trim());
                  _controller.clear();
                  ref.invalidate(lessonNotesProvider(widget.lessonId));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
