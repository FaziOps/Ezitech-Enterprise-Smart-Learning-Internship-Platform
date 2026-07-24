import 'package:equatable/equatable.dart';

enum LiveSessionState { upcoming, live, ended }

class LiveSessionEntity extends Equatable {
  const LiveSessionEntity({
    required this.id,
    required this.title,
    required this.hostName,
    required this.startsAt,
    required this.durationMinutes,
    required this.joinUrl,
    required this.state,
    required this.attended,
  });

  final String id;
  final String title;
  final String hostName;
  final DateTime startsAt;
  final int durationMinutes;
  final String joinUrl;
  final LiveSessionState state;
  final bool attended;

  LiveSessionEntity copyWith({bool? attended}) => LiveSessionEntity(
        id: id,
        title: title,
        hostName: hostName,
        startsAt: startsAt,
        durationMinutes: durationMinutes,
        joinUrl: joinUrl,
        state: state,
        attended: attended ?? this.attended,
      );

  @override
  List<Object?> get props =>
      [id, title, hostName, startsAt, durationMinutes, joinUrl, state, attended];
}
