import '../../domain/entities/live_session_entity.dart';

class LiveSessionModel extends LiveSessionEntity {
  const LiveSessionModel({
    required super.id,
    required super.title,
    required super.hostName,
    required super.startsAt,
    required super.durationMinutes,
    required super.joinUrl,
    required super.state,
    required super.attended,
  });

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) => LiveSessionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        hostName: json['host_name'] as String,
        startsAt: DateTime.parse(json['starts_at'] as String),
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
        joinUrl: json['join_url'] as String,
        state: LiveSessionState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => LiveSessionState.upcoming,
        ),
        attended: json['attended'] as bool? ?? false,
      );
}
