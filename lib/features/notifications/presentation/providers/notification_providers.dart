import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/fcm_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

final fcmServiceProvider = Provider((ref) {
  final service = FcmService();
  ref.onDispose(service.dispose);
  return service;
});

final notificationLocalDataSourceProvider = Provider((ref) => NotificationLocalDataSource());

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    ref.watch(notificationLocalDataSourceProvider),
    ref.watch(fcmServiceProvider),
  ),
);

final notificationsListProvider = FutureProvider<List<NotificationEntity>>((ref) async {
  return ref.watch(notificationRepositoryProvider).getAll();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsListProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.read).length;
});

/// Live stream of newly-arrived FCM notifications while the app is
/// foregrounded — screens can listen to this to refresh the list without
/// polling.
final incomingNotificationProvider = StreamProvider<NotificationEntity>((ref) {
  return ref.watch(notificationRepositoryProvider).incoming;
});
