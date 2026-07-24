import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/assignment_entity.dart';
import '../providers/assignment_providers.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  final _githubController = TextEditingController();
  String? _pickedFileName;
  String? _pickedFilePath;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _pickedFileName = file.name;
      _pickedFilePath = file.path;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref.read(submitAssignmentUseCaseProvider).call(
          assignmentId: widget.assignmentId,
          filePath: _pickedFilePath,
          githubLink: _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        setState(() {
          _pickedFileName = null;
          _pickedFilePath = null;
        });
        _githubController.clear();
        ref.invalidate(submissionHistoryProvider(widget.assignmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission saved — will upload when online.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(assignmentDetailProvider(widget.assignmentId));
    final historyAsync = ref.watch(submissionHistoryProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Assignment'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Could not load assignment: $e')),
        data: (assignment) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
          children: [
            Text(assignment.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(assignment.description, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            GlassContainer(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Due ${assignment.dueAt.day}/${assignment.dueAt.month}/${assignment.dueAt.year}'),
                  const Spacer(),
                  if (assignment.evaluationScore != null)
                    Text(
                      'Score: ${assignment.evaluationScore}/100',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (assignment.status != AssignmentStatus.evaluated) ...[
              GlassContainer(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Submit your work', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_pickedFileName ?? 'Choose a file'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _githubController,
                      decoration: const InputDecoration(
                        hintText: 'https://github.com/you/repo (optional)',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit Assignment'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            historyAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (history) => history.isEmpty
                  ? const SizedBox.shrink()
                  : GlassContainer(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Submission History', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: AppSpacing.sm),
                          for (final s in history)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    s.synced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                                    size: 16,
                                    color: s.synced ? AppColors.secondary : AppColors.warning,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      s.githubLink ?? s.filePath ?? 'Submission',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    s.synced ? 'Synced' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: s.synced ? AppColors.textMuted : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
