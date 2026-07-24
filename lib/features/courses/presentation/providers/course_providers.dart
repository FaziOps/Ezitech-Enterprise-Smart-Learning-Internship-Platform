import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/course_local_datasource.dart';
import '../../data/datasources/course_remote_datasource.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/usecases/resume_learning_usecase.dart';

final courseRemoteDataSourceProvider =
    Provider((ref) => CourseRemoteDataSource(ref.watch(apiClientProvider)));
final courseLocalDataSourceProvider = Provider((ref) => CourseLocalDataSource());

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final impl = CourseRepositoryImpl(
    ref.watch(courseRemoteDataSourceProvider),
    ref.watch(courseLocalDataSourceProvider),
    ref.watch(outboxQueueProvider),
    ref.watch(downloadManagerProvider),
  );
  // Register this repository's sync handlers with the shared SyncWorker
  // once, at provider construction — see core/offline/sync_worker.dart.
  final worker = ref.watch(syncWorkerProvider);
  worker.registerHandler('lesson_progress', impl.syncProgress);
  worker.registerHandler('note', impl.syncNote);
  return impl;
});

/// Cast helper — the domain-facing provider above exposes the interface,
/// but the download-path helpers below are implementation-specific
/// (real file caching is a data-layer concern, not part of the abstract
/// CourseRepository contract other features might fake in tests).
CourseRepositoryImpl _impl(Ref ref) => ref.watch(courseRepositoryProvider) as CourseRepositoryImpl;

final localVideoPathProvider = FutureProvider.family<String?, String>(
  (ref, lessonId) => _impl(ref).localVideoPath(lessonId),
);
final localPdfPathProvider = FutureProvider.family<String?, String>(
  (ref, lessonId) => _impl(ref).localPdfPath(lessonId),
);

final resumeLearningUseCaseProvider =
    Provider((ref) => ResumeLearningUseCase(ref.watch(courseRepositoryProvider)));

final coursesListProvider = FutureProvider<List<CourseEntity>>((ref) async {
  final result = await ref.watch(courseRepositoryProvider).getCourses();
  return result.fold((failure) => throw failure.message, (courses) => courses);
});

final courseDetailProvider =
    FutureProvider.family<CourseDetailEntity, String>((ref, courseId) async {
  final result = await ref.watch(courseRepositoryProvider).getCourseDetail(courseId);
  return result.fold((failure) => throw failure.message, (detail) => detail);
});

final courseProgressProvider =
    FutureProvider.family<CourseProgressEntity, String>((ref, courseId) async {
  final result = await ref.watch(courseRepositoryProvider).getProgress(courseId);
  return result.fold(
    (failure) => CourseProgressEntity.empty(courseId),
    (progress) => progress,
  );
});

final lessonNotesProvider = FutureProvider.family<List<NoteEntity>, String>((ref, lessonId) async {
  final result = await ref.watch(courseRepositoryProvider).getNotes(lessonId);
  return result.fold((failure) => <NoteEntity>[], (notes) => notes);
});
