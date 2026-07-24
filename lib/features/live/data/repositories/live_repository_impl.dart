import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/offline/outbox_item.dart';
import '../../../../core/offline/outbox_queue.dart';
import '../../../../core/utils/failure.dart';
import '../../domain/entities/live_session_entity.dart';
import '../../domain/repositories/live_repository.dart';
import '../datasources/live_remote_datasource.dart';
import '../models/live_session_model.dart';

class LiveRepositoryImpl implements LiveRepository {
  LiveRepositoryImpl(this._remote, this._outbox);

  final LiveRemoteDataSource _remote;
  final OutboxQueue _outbox;
  final _uuid = const Uuid();
  static const _boxName = 'live_sessions_box';

  Box get _box => Hive.box(_boxName);

  static Future<void> openBox() async => Hive.openBox(_boxName);

  @override
  Future<Result<List<LiveSessionEntity>>> getSchedule() async {
    try {
      final sessions = await _remote.getSchedule();
      await _cache(sessions);
      return Result.success(sessions);
    } catch (_) {
      final cached = _cached();
      if (cached.isNotEmpty) return Result.success(cached);
      final seeded = _seedSessions();
      await _cache(seeded);
      return Result.success(seeded);
    }
  }

  List<LiveSessionModel> _seedSessions() {
    final now = DateTime.now();
    return [
      LiveSessionModel(
        id: 'ls1',
        title: 'Week 3 Architecture Review',
        hostName: 'Ayesha Raza',
        startsAt: now.add(const Duration(hours: 4)),
        durationMinutes: 45,
        joinUrl: 'https://meet.google.com/aog-yfnq-jzd',
        state: LiveSessionState.upcoming,
        attended: false,
      ),
      LiveSessionModel(
        id: 'ls2',
        title: 'Offline-First Patterns Q&A',
        hostName: 'Ezitech Faculty',
        startsAt: now.subtract(const Duration(days: 2)),
        durationMinutes: 60,
        joinUrl: 'https://meet.google.com/aog-yfnq-jzd',
        state: LiveSessionState.ended,
        attended: true,
      ),
    ];
  }

  Future<void> _cache(List<LiveSessionModel> sessions) async {
    await _box.put(
      'all',
      sessions
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'host_name': s.hostName,
                'starts_at': s.startsAt.toIso8601String(),
                'duration_minutes': s.durationMinutes,
                'join_url': s.joinUrl,
                'state': s.state.name,
                'attended': s.attended,
              })
          .toList(),
    );
  }

  List<LiveSessionModel> _cached() {
    final raw = _box.get('all') as List? ?? [];
    return raw
        .map((e) => LiveSessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> markAttendance(String sessionId) async {
    final sessions = _cached();
    final updated = sessions
        .map((s) => s.id == sessionId
            ? LiveSessionModel(
                id: s.id,
                title: s.title,
                hostName: s.hostName,
                startsAt: s.startsAt,
                durationMinutes: s.durationMinutes,
                joinUrl: s.joinUrl,
                state: s.state,
                attended: true,
              )
            : s)
        .toList();
    await _cache(updated);

    await _outbox.enqueue(OutboxItem(
      id: _uuid.v4(),
      payloadType: 'live_attendance',
      payloadJson: {'session_id': sessionId, 'marked_at': DateTime.now().toIso8601String()},
      createdAt: DateTime.now(),
    ));
  }

  /// Called by SyncWorker for live_attendance items.
  Future<void> syncAttendance(Map<String, dynamic> payload) => _remote.syncAttendance(payload);
}
