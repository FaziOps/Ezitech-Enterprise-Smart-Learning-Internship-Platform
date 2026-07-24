import 'package:hive/hive.dart';
import 'outbox_item.dart';

/// Thin wrapper around the Hive box that stores pending writes.
///
/// Every offline-first repository (Internship, Assignments, Course
/// progress/notes) writes here first and reflects the change in its
/// local cache immediately (optimistic update) — the UI never waits on
/// the network for a write to "feel" complete. [SyncWorker] drains this
/// queue whenever connectivity returns.
class OutboxQueue {
  static const boxName = 'outbox_box';

  Box<OutboxItem> get _box => Hive.box<OutboxItem>(boxName);

  static Future<void> registerAndOpen() async {
    if (!Hive.isAdapterRegistered(OutboxItemAdapter().typeId)) {
      Hive.registerAdapter(OutboxItemAdapter());
    }
    await Hive.openBox<OutboxItem>(boxName);
  }

  Future<void> enqueue(OutboxItem item) async {
    await _box.put(item.id, item);
  }

  List<OutboxItem> pendingItems({String? ofType}) {
    final all = _box.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (ofType == null) return all;
    return all.where((i) => i.payloadType == ofType).toList();
  }

  Future<void> markSynced(String id) async {
    await _box.delete(id);
  }

  Future<void> recordFailure(String id, String error) async {
    final item = _box.get(id);
    if (item == null) return;
    item.attemptCount += 1;
    item.lastError = error;
    // Exponential backoff, capped at 5 minutes per item — matches the
    // Implementation Plan's Section 3.3 "retry and exponential backoff
    // on failure" requirement. attemptCount 1 -> 10s, 2 -> 20s, 3 -> 40s,
    // ... capped so a permanently-broken item doesn't wait forever
    // between checks (it still needs a human to notice eventually —
    // see attemptsExceedingThreshold below).
    final backoffSeconds = (10 * (1 << item.attemptCount)).clamp(10, 300);
    item.nextRetryAt = DateTime.now().add(Duration(seconds: backoffSeconds));
    await item.save();
  }

  /// Items that have failed enough times to warrant surfacing to the
  /// student as "this isn't syncing, you may want to check it" rather
  /// than silently retrying forever.
  List<OutboxItem> itemsNeedingAttention({int threshold = 5}) {
    return _box.values.where((i) => i.attemptCount >= threshold).toList();
  }

  int get pendingCount => _box.length;

  Stream<void> watch() => _box.watch().map((_) {});
}
