import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getAll();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Stream<NotificationEntity> get incoming;
  Future<String?> getDeviceToken();
}
