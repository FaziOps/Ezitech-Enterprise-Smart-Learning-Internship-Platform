import 'package:uuid/uuid.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/fcm_service.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._local, this._fcm) {
    // Bridges FCM RemoteMessages into the domain-typed stream, and
    // persists them so they still appear in the Notification Center
    // after the app is closed and reopened.
    _fcm.onMessage.listen((message) async {
      final model = NotificationModel(
        id: message.messageId ?? _uuid.v4(),
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        type: _typeFromData(message.data['type']),
        receivedAt: DateTime.now(),
        read: false,
        deepLinkPath: message.data['deep_link_path'] as String?,
      );
      await _local.add(model);
    });
  }

  final NotificationLocalDataSource _local;
  final FcmService _fcm;
  final _uuid = const Uuid();

  NotificationType _typeFromData(dynamic value) {
    return NotificationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => NotificationType.courseUpdate,
    );
  }

  @override
  Future<List<NotificationEntity>> getAll() async {
    final cached = _local.getAll();
    if (cached.isNotEmpty) return cached;
    // Seed data so the Notification Center is demoable before a real
    // Firebase project (README API table #9) is wired in — matches the
    // MVP journey's "deadline reminder" and mentor-announcement examples.
    final seeded = _seedNotifications();
    await _local.saveAll(seeded);
    return seeded;
  }

  List<NotificationModel> _seedNotifications() => [
        NotificationModel(
          id: 'n1',
          title: 'Assignment due soon',
          body: 'Offline Outbox Queue Implementation is due in 2 days.',
          type: NotificationType.assignmentDeadline,
          receivedAt: DateTime.now().subtract(const Duration(hours: 2)),
          read: false,
          deepLinkPath: '/assignments/a1',
        ),
        NotificationModel(
          id: 'n2',
          title: 'Mentor feedback received',
          body: 'Ayesha Raza left feedback on your Week 1 submission.',
          type: NotificationType.mentorAnnouncement,
          receivedAt: DateTime.now().subtract(const Duration(days: 1)),
          read: true,
          deepLinkPath: '/internship',
        ),
      ];

  @override
  Future<void> markRead(String id) => _local.markRead(id);

  @override
  Future<void> markAllRead() => _local.markAllRead();

  @override
  Stream<NotificationEntity> get incoming => _fcm.onMessage.map((message) => NotificationModel(
        id: message.messageId ?? _uuid.v4(),
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        type: _typeFromData(message.data['type']),
        receivedAt: DateTime.now(),
        read: false,
        deepLinkPath: message.data['deep_link_path'] as String?,
      ));

  @override
  Future<String?> getDeviceToken() => _fcm.getToken();
}
