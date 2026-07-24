import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsListProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Could not load notifications: $e')),
        data: (notifications) => notifications.isEmpty
            ? const Center(
                child: Text('No notifications yet.', style: TextStyle(color: AppColors.textMuted)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final n = notifications[i];
                  return GlassCard(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () async {
                      if (!n.read) {
                        await ref.read(notificationRepositoryProvider).markRead(n.id);
                        ref.invalidate(notificationsListProvider);
                      }
                      if (n.deepLinkPath != null && context.mounted) {
                        context.push(n.deepLinkPath!);
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFor(n.type), color: _colorFor(n.type), size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.read ? FontWeight.normal : FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(n.body, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.assignmentDeadline => Icons.event_outlined,
        NotificationType.mentorAnnouncement => Icons.record_voice_over_outlined,
        NotificationType.courseUpdate => Icons.menu_book_outlined,
        NotificationType.liveSessionAlert => Icons.videocam_outlined,
        NotificationType.certificate => Icons.workspace_premium_outlined,
        NotificationType.internshipReminder => Icons.work_outline,
      };

  Color _colorFor(NotificationType type) => switch (type) {
        NotificationType.assignmentDeadline => AppColors.danger,
        NotificationType.mentorAnnouncement => AppColors.secondary,
        NotificationType.courseUpdate => AppColors.primary,
        NotificationType.liveSessionAlert => AppColors.warning,
        NotificationType.certificate => AppColors.aiAccent,
        NotificationType.internshipReminder => AppColors.secondary,
      };
}
