import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'outbox_queue.dart';

typedef OutboxSyncHandler = Future<void> Function(Map<String, dynamic> payloadJson);

enum SyncStatus { idle, syncing, error }

/// Central background sync coordinator.
///
/// Week 3 change from the Week 2 version: retries now actually respect
/// per-item exponential backoff (via `OutboxItem.nextRetryAt`, computed
/// in [OutboxQueue.recordFailure]) instead of just "wait for the next
/// connectivity event." A lightweight periodic timer checks for items
/// whose backoff has elapsed, in addition to draining immediately on
/// reconnect. This is what the Implementation Plan's Section 3.3 actually
/// asked for — the Week 2 version only had half of it.
///
/// Design: repositories register a handler for their payload type at app
/// start (see `registerHandler` calls in each feature's provider file).
/// This worker never imports Dio or any repository directly.
class SyncWorker {
  SyncWorker(this._outbox);

  final OutboxQueue _outbox;
  final Map<String, OutboxSyncHandler> _handlers = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _backoffTimer;
  bool _draining = false;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  void registerHandler(String payloadType, OutboxSyncHandler handler) {
    _handlers[payloadType] = handler;
  }

  void start() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) drainQueue();
    });

    // Checks every 15s for items whose individual backoff window has
    // elapsed — catches the case where connectivity was already up when
    // an item failed, so no new connectivity *event* will ever fire to
    // trigger a retry.
    _backoffTimer = Timer.periodic(const Duration(seconds: 15), (_) => drainQueue());

    drainQueue(); // attempt once at startup
  }

  void dispose() {
    _connectivitySub?.cancel();
    _backoffTimer?.cancel();
    _statusController.close();
  }

  Future<void> drainQueue() async {
    if (_draining) return;
    _draining = true;
    final now = DateTime.now();
    final due = _outbox.pendingItems().where((i) => !i.nextRetryAt.isAfter(now)).toList();

    if (due.isEmpty) {
      _draining = false;
      return;
    }

    _statusController.add(SyncStatus.syncing);
    var hadError = false;

    try {
      for (final item in due) {
        final handler = _handlers[item.payloadType];
        if (handler == null) continue; // unknown type, leave queued
        try {
          await handler(item.payloadJson);
          await _outbox.markSynced(item.id);
        } catch (e) {
          hadError = true;
          await _outbox.recordFailure(item.id, e.toString());
        }
      }
    } finally {
      _draining = false;
      _statusController.add(hadError ? SyncStatus.error : SyncStatus.idle);
    }
  }

  /// Manual "retry now" trigger — wired to a button on items flagged by
  /// [OutboxQueue.itemsNeedingAttention] so the student isn't purely at
  /// the mercy of the timer.
  Future<void> retryNow() => drainQueue();
}
