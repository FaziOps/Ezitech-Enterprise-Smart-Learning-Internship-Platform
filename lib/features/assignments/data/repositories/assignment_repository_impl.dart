import 'package:uuid/uuid.dart';
import '../../../../core/offline/outbox_item.dart';
import '../../../../core/offline/outbox_queue.dart';
import '../../../../core/utils/failure.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/assignment_local_datasource.dart';
import '../datasources/assignment_remote_datasource.dart';
import '../models/assignment_model.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  AssignmentRepositoryImpl(this._remote, this._local, this._outbox);

  final AssignmentRemoteDataSource _remote;
  final AssignmentLocalDataSource _local;
  final OutboxQueue _outbox;
  final _uuid = const Uuid();

  @override
  Future<Result<List<AssignmentEntity>>> getAssignments() async {
    try {
      final assignments = await _remote.getAssignments();
      await _local.cacheAssignments(assignments);
      return Result.success(assignments);
    } catch (_) {
      final cached = _local.getCachedAssignments();
      if (cached.isNotEmpty) return Result.success(cached);
      final seeded = _seedAssignments();
      await _local.cacheAssignments(seeded);
      return Result.success(seeded);
    }
  }

  List<AssignmentModel> _seedAssignments() => [
        AssignmentModel(
          id: 'a1',
          title: 'Offline Outbox Queue Implementation',
          description:
              'Implement a Hive-backed offline outbox with a connectivity-triggered '
              'sync worker. Submit your repo link or a zipped source export.',
          dueAt: DateTime.now().add(const Duration(days: 2)),
          status: AssignmentStatus.pending,
          evaluationScore: null,
        ),
        AssignmentModel(
          id: 'a2',
          title: 'Clean Architecture Case Study Writeup',
          description:
              'Write up how your Internship Portal module separates domain, data, '
              'and presentation layers, with a short justification for each boundary.',
          dueAt: DateTime.now().add(const Duration(days: 5)),
          status: AssignmentStatus.pending,
          evaluationScore: null,
        ),
        AssignmentModel(
          id: 'a3',
          title: 'Week 1 Glass Morphism Design System',
          description: 'Submitted foundation covering login and dashboard screens.',
          dueAt: DateTime.now().subtract(const Duration(days: 3)),
          status: AssignmentStatus.evaluated,
          evaluationScore: 88,
        ),
      ];

  @override
  Future<Result<AssignmentEntity>> getAssignmentDetail(String assignmentId) async {
    try {
      return Result.success(await _remote.getAssignmentDetail(assignmentId));
    } catch (_) {
      final all = _local.getCachedAssignments();
      final match = all.where((a) => a.id == assignmentId);
      if (match.isNotEmpty) return Result.success(match.first);
      return const Result.failure(NetworkFailure('Assignment not available offline yet.'));
    }
  }

  @override
  Future<Result<List<SubmissionEntity>>> getSubmissionHistory(String assignmentId) async {
    return Result.success(_local.getCachedSubmissions(assignmentId));
  }

  @override
  Future<void> submitAssignment({
    required String assignmentId,
    String? filePath,
    String? githubLink,
  }) async {
    final submission = SubmissionModel(
      id: _uuid.v4(),
      assignmentId: assignmentId,
      filePath: filePath,
      githubLink: githubLink,
      submittedAt: DateTime.now(),
      synced: false,
    );
    await _local.addLocalSubmission(assignmentId, submission);
    await _outbox.enqueue(OutboxItem(
      id: submission.id,
      payloadType: OutboxPayloadType.assignmentSubmission,
      payloadJson: submission.toJson(),
      createdAt: DateTime.now(),
    ));
  }

  /// Called by SyncWorker when an assignment_submission item drains.
  Future<void> syncSubmission(Map<String, dynamic> payload) async {
    await _remote.submitAssignment(payload);
    await _local.markSubmissionSynced(
      payload['assignment_id'] as String,
      payload['id'] as String,
    );
  }
}
