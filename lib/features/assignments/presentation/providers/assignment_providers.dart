import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../data/datasources/assignment_local_datasource.dart';
import '../../data/datasources/assignment_remote_datasource.dart';
import '../../data/repositories/assignment_repository_impl.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../../domain/usecases/submit_assignment_usecase.dart';

final assignmentRemoteDataSourceProvider =
    Provider((ref) => AssignmentRemoteDataSource(ref.watch(apiClientProvider)));
final assignmentLocalDataSourceProvider = Provider((ref) => AssignmentLocalDataSource());

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final impl = AssignmentRepositoryImpl(
    ref.watch(assignmentRemoteDataSourceProvider),
    ref.watch(assignmentLocalDataSourceProvider),
    ref.watch(outboxQueueProvider),
  );
  final worker = ref.watch(syncWorkerProvider);
  worker.registerHandler('assignment_submission', impl.syncSubmission);
  return impl;
});

final submitAssignmentUseCaseProvider =
    Provider((ref) => SubmitAssignmentUseCase(ref.watch(assignmentRepositoryProvider)));

final assignmentsListProvider = FutureProvider<List<AssignmentEntity>>((ref) async {
  final result = await ref.watch(assignmentRepositoryProvider).getAssignments();
  return result.fold((f) => <AssignmentEntity>[], (v) => v);
});

final assignmentDetailProvider =
    FutureProvider.family<AssignmentEntity, String>((ref, assignmentId) async {
  final result = await ref.watch(assignmentRepositoryProvider).getAssignmentDetail(assignmentId);
  return result.fold((f) => throw f.message, (v) => v);
});

final submissionHistoryProvider =
    FutureProvider.family<List<SubmissionEntity>, String>((ref, assignmentId) async {
  final result = await ref.watch(assignmentRepositoryProvider).getSubmissionHistory(assignmentId);
  return result.fold((f) => <SubmissionEntity>[], (v) => v);
});
