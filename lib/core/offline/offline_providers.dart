import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'download_manager.dart';
import 'outbox_queue.dart';
import 'sync_worker.dart';

final outboxQueueProvider = Provider((ref) => OutboxQueue());
final downloadManagerProvider = Provider((ref) => DownloadManager());

final syncWorkerProvider = Provider((ref) {
  final worker = SyncWorker(ref.watch(outboxQueueProvider));
  ref.onDispose(worker.dispose);
  return worker;
});

/// Live connectivity status, watched by [OfflineIndicator] so the student
/// always knows whether they're looking at synced or pending-sync data —
/// per the Implementation Plan's "persistent but unobtrusive offline
/// indicator" requirement.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});

/// Number of items currently waiting to sync — surfaced next to the
/// offline indicator ("3 changes pending sync").
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final outbox = ref.watch(outboxQueueProvider);
  return outbox.watch().map((_) => outbox.pendingCount).distinct();
});

/// Week 3 addition: whether the sync worker is actively syncing, idle, or
/// hit an error on its last pass — lets the offline indicator distinguish
/// "3 pending, working on it" from "3 pending, and failing."
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncWorkerProvider).statusStream;
});

/// Items that have failed repeatedly and need a human to notice —
/// re-derived whenever the outbox changes.
final stuckOutboxItemsCountProvider = StreamProvider<int>((ref) {
  final outbox = ref.watch(outboxQueueProvider);
  return outbox.watch().map((_) => outbox.itemsNeedingAttention().length).distinct();
});
