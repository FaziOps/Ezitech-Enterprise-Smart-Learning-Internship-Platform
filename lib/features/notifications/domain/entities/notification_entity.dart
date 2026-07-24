import 'package:equatable/equatable.dart';

enum NotificationType {
  assignmentDeadline,
  mentorAnnouncement,
  courseUpdate,
  liveSessionAlert,
  certificate,
  internshipReminder,
}

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.receivedAt,
    required this.read,
    this.deepLinkPath,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime receivedAt;
  final bool read;
  /// e.g. "/assignments/a1" — matches the MVP journey's "push notification
  /// arrives and opens directly to the relevant assignment" step.
  final String? deepLinkPath;

  NotificationEntity copyWith({bool? read}) => NotificationEntity(
        id: id,
        title: title,
        body: body,
        type: type,
        receivedAt: receivedAt,
        read: read ?? this.read,
        deepLinkPath: deepLinkPath,
      );

  @override
  List<Object?> get props => [id, title, body, type, receivedAt, read, deepLinkPath];
}
