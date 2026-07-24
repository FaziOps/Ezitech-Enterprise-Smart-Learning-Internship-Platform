import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../data/datasources/live_remote_datasource.dart';
import '../../data/repositories/live_repository_impl.dart';
import '../../domain/entities/live_session_entity.dart';
import '../../domain/repositories/live_repository.dart';

final liveRemoteDataSourceProvider =
    Provider((ref) => LiveRemoteDataSource(ref.watch(apiClientProvider)));

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  final impl =
      LiveRepositoryImpl(ref.watch(liveRemoteDataSourceProvider), ref.watch(outboxQueueProvider));
  final worker = ref.watch(syncWorkerProvider);
  worker.registerHandler('live_attendance', impl.syncAttendance);
  return impl;
});

final liveScheduleProvider = FutureProvider<List<LiveSessionEntity>>((ref) async {
  final result = await ref.watch(liveRepositoryProvider).getSchedule();
  return result.fold((f) => <LiveSessionEntity>[], (v) => v);
});
