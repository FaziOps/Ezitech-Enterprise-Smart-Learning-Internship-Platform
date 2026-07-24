import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../data/datasources/internship_local_datasource.dart';
import '../../data/datasources/internship_remote_datasource.dart';
import '../../data/repositories/internship_repository_impl.dart';
import '../../domain/entities/internship_entity.dart';
import '../../domain/repositories/internship_repository.dart';
import '../../domain/usecases/submit_weekly_report_usecase.dart';

final internshipRemoteDataSourceProvider =
    Provider((ref) => InternshipRemoteDataSource(ref.watch(apiClientProvider)));
final internshipLocalDataSourceProvider = Provider((ref) => InternshipLocalDataSource());

final internshipRepositoryProvider = Provider<InternshipRepository>((ref) {
  final impl = InternshipRepositoryImpl(
    ref.watch(internshipRemoteDataSourceProvider),
    ref.watch(internshipLocalDataSourceProvider),
    ref.watch(outboxQueueProvider),
  );
  final worker = ref.watch(syncWorkerProvider);
  worker.registerHandler('weekly_report', impl.syncWeeklyReport);
  worker.registerHandler('internship_task_toggle', impl.syncTaskToggle);
  return impl;
});

final submitWeeklyReportUseCaseProvider = Provider(
  (ref) => SubmitWeeklyReportUseCase(ref.watch(internshipRepositoryProvider)),
);

final caseStudyProvider = FutureProvider<CaseStudyEntity>((ref) async {
  final result = await ref.watch(internshipRepositoryProvider).getAssignedCaseStudy();
  return result.fold((f) => throw f.message, (v) => v);
});

final internshipTasksProvider = FutureProvider<List<InternshipTaskEntity>>((ref) async {
  final result = await ref.watch(internshipRepositoryProvider).getDailyTasks();
  return result.fold((f) => <InternshipTaskEntity>[], (v) => v);
});

final mentorFeedbackProvider = FutureProvider<List<MentorFeedbackEntity>>((ref) async {
  final result = await ref.watch(internshipRepositoryProvider).getMentorFeedback();
  return result.fold((f) => <MentorFeedbackEntity>[], (v) => v);
});

final submittedReportsProvider = FutureProvider<List<WeeklyReportEntity>>((ref) async {
  final result = await ref.watch(internshipRepositoryProvider).getSubmittedReports();
  return result.fold((f) => <WeeklyReportEntity>[], (v) => v);
});
