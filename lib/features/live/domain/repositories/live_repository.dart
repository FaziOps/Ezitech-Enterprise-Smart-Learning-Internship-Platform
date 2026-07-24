import '../../../../core/utils/failure.dart';
import '../entities/live_session_entity.dart';

/// Scope note: chat and recording playback are explicitly Full-Scope
/// Backlog per the Implementation Plan Section 4.3 — this MVP module is
/// deliberately schedule + join + attendance only.
abstract class LiveRepository {
  Future<Result<List<LiveSessionEntity>>> getSchedule();
  Future<void> markAttendance(String sessionId);
}
