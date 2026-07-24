import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/offline_indicator.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/entities/live_session_entity.dart';
import '../providers/live_providers.dart';

class LiveLearningScreen extends ConsumerWidget {
  const LiveLearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(liveScheduleProvider);

    return ResponsiveCenter(
      child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(child: Text('Live Learning', style: Theme.of(context).textTheme.headlineSmall)),
                const OfflineIndicator(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: scheduleAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => SliverToBoxAdapter(child: GlassContainer(child: Text('Error: $e'))),
            data: (sessions) => SliverList.separated(
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _SessionCard(session: sessions[i]),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});
  final LiveSessionEntity session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = switch (session.state) {
      LiveSessionState.upcoming => ('Upcoming', AppColors.warning),
      LiveSessionState.live => ('Live now', AppColors.danger),
      LiveSessionState.ended => ('Ended', AppColors.textMuted),
    };

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(session.title, style: Theme.of(context).textTheme.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(label, style: TextStyle(fontSize: 11, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hosted by ${session.hostName} · ${session.durationMinutes} min',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          Text(
            _formatDateTime(session.startsAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (session.state != LiveSessionState.ended)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showJoinDialog(context, session.joinUrl),
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: const Text('Join'),
                  ),
                ),
              if (session.state != LiveSessionState.ended) const SizedBox(width: AppSpacing.sm),
              if (session.state != LiveSessionState.ended)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/live/${session.id}/chat', extra: session),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Chat'),
                  ),
                ),
              if (session.state != LiveSessionState.ended) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: session.attended
                      ? null
                      : () async {
                          await ref.read(liveRepositoryProvider).markAttendance(session.id);
                          ref.invalidate(liveScheduleProvider);
                        },
                  icon: Icon(
                    session.attended ? Icons.check_circle : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(session.attended ? 'Attended' : 'Mark'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinDialog(BuildContext context, String url) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Join Live Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Here is the meeting link provided by your teacher:',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                url,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meeting link copied to clipboard.')),
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Copy Link'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final uri = Uri.parse(url);
                final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open the meeting link.')),
                  );
                }
              },
              child: const Text('Join Class'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return isToday ? 'Today, $time' : '${dt.day}/${dt.month}/${dt.year}, $time';
  }
}
