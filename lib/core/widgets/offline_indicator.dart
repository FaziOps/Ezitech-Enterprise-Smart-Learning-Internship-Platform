import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../offline/offline_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'glass_container.dart';

/// A slim glass pill shown only when relevant (offline, syncing, or
/// something is stuck) — deliberately absent when everything is synced
/// and online, so it never nags the student in the common case.
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityStatusProvider).valueOrNull ?? true;
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final stuckCount = ref.watch(stuckOutboxItemsCountProvider).valueOrNull ?? 0;

    if (isOnline && pendingCount == 0) return const SizedBox.shrink();

    final (label, color, icon) = _resolveState(isOnline, pendingCount, stuckCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: GestureDetector(
        onTap: stuckCount > 0
            ? () {
                ref.read(syncWorkerProvider).retryNow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Retrying pending sync…')),
                );
              }
            : null,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, IconData) _resolveState(bool isOnline, int pendingCount, int stuckCount) {
    if (stuckCount > 0) {
      return ('$stuckCount need attention · tap to retry', AppColors.danger, Icons.error_outline);
    }
    if (!isOnline) {
      return (
        pendingCount > 0 ? 'Offline · $pendingCount pending' : 'Offline',
        AppColors.warning,
        Icons.cloud_off_outlined,
      );
    }
    return (
      'Syncing $pendingCount change${pendingCount == 1 ? '' : 's'}…',
      AppColors.secondary,
      Icons.sync,
    );
  }
}
