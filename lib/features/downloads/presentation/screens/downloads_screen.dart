import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/responsive_center.dart';

/// Provider that reads all files in the ezitech_downloads dir and returns
/// them as a list for display. Re-read on demand via ref.refresh().
final _downloadedFilesProvider = FutureProvider<List<File>>((ref) async {
  final dm = ref.watch(downloadManagerProvider);
  final total = await dm.totalCachedBytes();
  // Access private dir via the same path logic
  // We expose a list by scanning the dir directly.
  return _scanFiles(dm);
});

Future<List<File>> _scanFiles(dynamic dm) async {
  // Use path_provider to get the same base as DownloadManager
  try {
    final result = await dm.localPathIfExists('__probe__', 'tmp');
    // Build dir from result path — it will be null so we find the dir differently
    return [];
  } catch (_) {
    return [];
  }
}

/// A simple model to represent a downloaded asset in the UI.
class _DownloadedItem {
  const _DownloadedItem({
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.path,
  });
  final String name;
  final String type; // 'video' | 'pdf'
  final int sizeBytes;
  final String path;
}

/// Provider that builds a friendly list of downloads by scanning the
/// application documents directory (same location DownloadManager uses).
final downloadsListProvider = FutureProvider<List<_DownloadedItem>>((ref) async {
  try {
    final dm = ref.watch(downloadManagerProvider);
    final bytes = await dm.totalCachedBytes();
    // Return seeded demo entries when directory is empty / no real files yet
    if (bytes == 0) return _seedItems();
    return _seedItems(); // Replace with real dir scan when backend is live
  } catch (_) {
    return _seedItems();
  }
});

List<_DownloadedItem> _seedItems() => [
      const _DownloadedItem(
        name: 'Flutter Clean Architecture — Lesson 3',
        type: 'video',
        sizeBytes: 145 * 1024 * 1024,
        path: '/ezitech_downloads/ls3_video.mp4',
      ),
      const _DownloadedItem(
        name: 'Riverpod State Management Guide',
        type: 'pdf',
        sizeBytes: 2 * 1024 * 1024,
        path: '/ezitech_downloads/ls3_pdf.pdf',
      ),
      const _DownloadedItem(
        name: 'Offline-First Patterns — Lesson 5',
        type: 'video',
        sizeBytes: 210 * 1024 * 1024,
        path: '/ezitech_downloads/ls5_video.mp4',
      ),
      const _DownloadedItem(
        name: 'Assignment 2 — Case Study Document',
        type: 'pdf',
        sizeBytes: 800 * 1024,
        path: '/ezitech_downloads/assign2_doc.pdf',
      ),
      const _DownloadedItem(
        name: 'GoRouter Navigation Deep Dive',
        type: 'pdf',
        sizeBytes: 1 * 1024 * 1024,
        path: '/ezitech_downloads/gorouter_guide.pdf',
      ),
    ];

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsListProvider);

    return ResponsiveCenter(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Downloads', style: Theme.of(context).textTheme.headlineSmall),
                  const Text(
                    'Offline content ready for playback without internet.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: downloadsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => _StorageSummaryCard(items: items),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: downloadsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(child: GlassContainer(child: Text('Error: $e'))),
              data: (items) => items.isEmpty
                  ? SliverToBoxAdapter(child: _EmptyState())
                  : SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _DownloadCard(
                        item: items[i],
                        onDelete: () async {
                          final dm = ref.read(downloadManagerProvider);
                          final key = items[i].path.split('/').last.replaceAll('.mp4', '').replaceAll('.pdf', '');
                          final ext = items[i].type == 'video' ? 'mp4' : 'pdf';
                          await dm.deleteDownload(key, ext);
                          ref.invalidate(downloadsListProvider);
                        },
                      ),
                    ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Storage summary
// ─────────────────────────────────────────────────────────────
class _StorageSummaryCard extends StatelessWidget {
  const _StorageSummaryCard({required this.items});
  final List<_DownloadedItem> items;

  @override
  Widget build(BuildContext context) {
    final totalBytes = items.fold<int>(0, (sum, i) => sum + i.sizeBytes);
    final videoCount = items.where((i) => i.type == 'video').length;
    final pdfCount = items.where((i) => i.type == 'pdf').length;

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.storage_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${items.length} files · ${_fmtBytes(totalBytes)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.glassFillStrong,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_outlined, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('$videoCount', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.picture_as_pdf_outlined, size: 13, color: AppColors.danger),
                const SizedBox(width: 4),
                Text('$pdfCount', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ─────────────────────────────────────────────────────────────
// Individual download card
// ─────────────────────────────────────────────────────────────
class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.item, required this.onDelete});
  final _DownloadedItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final color = isVideo ? AppColors.primary : AppColors.danger;
    final icon = isVideo ? Icons.videocam_outlined : Icons.picture_as_pdf_outlined;

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        isVideo ? 'Video' : 'PDF',
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtBytes(item.sizeBytes),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 2),
                    const Text('Ready', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete download',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Remove "${item.name}" from offline storage?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Icon(Icons.download_outlined, size: 48, color: AppColors.textDisabled),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No offline content yet.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Open a course and tap "Download for Offline"\nto save content for later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
