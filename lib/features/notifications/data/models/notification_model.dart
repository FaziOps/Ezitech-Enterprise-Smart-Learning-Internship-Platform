import 'package:hive/hive.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.receivedAt,
    required super.read,
    super.deepLinkPath,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.courseUpdate,
        ),
        receivedAt: DateTime.parse(json['received_at'] as String),
        read: json['read'] as bool? ?? false,
        deepLinkPath: json['deep_link_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'received_at': receivedAt.toIso8601String(),
        'read': read,
        'deep_link_path': deepLinkPath,
      };

  factory NotificationModel.fromEntity(NotificationEntity e) => NotificationModel(
        id: e.id,
        title: e.title,
        body: e.body,
        type: e.type,
        receivedAt: e.receivedAt,
        read: e.read,
        deepLinkPath: e.deepLinkPath,
      );
}

class NotificationLocalDataSource {
  static const box = 'notifications_box';

  static Future<void> openBox() async => Hive.openBox(box);

  Box get _box => Hive.box(box);

  Future<void> saveAll(List<NotificationModel> notifications) async {
    await _box.put('all', notifications.map((n) => n.toJson()).toList());
  }

  List<NotificationModel> getAll() {
    final raw = _box.get('all') as List? ?? [];
    return raw
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  Future<void> add(NotificationModel notification) async {
    final all = getAll();
    all.insert(0, notification);
    await saveAll(all);
  }

  Future<void> markRead(String id) async {
    final all = getAll()
        .map((n) => n.id == id ? NotificationModel.fromEntity(n.copyWith(read: true)) : n)
        .toList();
    await saveAll(all);
  }

  Future<void> markAllRead() async {
    final all = getAll().map((n) => NotificationModel.fromEntity(n.copyWith(read: true))).toList();
    await saveAll(all);
  }
}
