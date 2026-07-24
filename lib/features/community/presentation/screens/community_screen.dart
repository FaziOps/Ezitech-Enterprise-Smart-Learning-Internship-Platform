import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/offline_indicator.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(communityFilterProvider);
    final postsAsync = ref.watch(communityPostsProvider(activeFilter));

    return ResponsiveCenter(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Community', style: Theme.of(context).textTheme.headlineSmall),
                        const Text(
                          'Discuss, collaborate and share with your peers.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const OfflineIndicator(),
                  const SizedBox(width: AppSpacing.sm),
                  _NewPostButton(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            sliver: SliverToBoxAdapter(child: _CategoryFilter()),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: postsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, st) => SliverToBoxAdapter(child: GlassContainer(child: Text('Error: $e'))),
              data: (posts) => posts.isEmpty
                  ? SliverToBoxAdapter(
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              'No posts in this category yet.\nBe the first to start a discussion!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList.separated(
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _PostCard(
                        post: posts[i],
                        onTap: () => context.push('/community/${posts[i].id}'),
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
// Category filter chips
// ─────────────────────────────────────────────────────────────
class _CategoryFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(communityFilterProvider);
    final filters = <(String, PostCategory?)>[
      ('All', null),
      ('General', PostCategory.general),
      ('Technology', PostCategory.technology),
      ('Projects', PostCategory.project),
      ('Announcements', PostCategory.announcement),
      ('Resources', PostCategory.resource),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, cat) in filters) ...[
            _FilterChip(
              label: label,
              selected: active == cat,
              onTap: () => ref.read(communityFilterProvider.notifier).state = cat,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.25) : AppColors.glassFillLight,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.glassBorder,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Post card
// ─────────────────────────────────────────────────────────────
class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.onTap});
  final CommunityPostEntity post;
  final VoidCallback onTap;

  static const _catColors = {
    PostCategory.general: AppColors.textMuted,
    PostCategory.technology: AppColors.primary,
    PostCategory.project: AppColors.secondary,
    PostCategory.announcement: AppColors.danger,
    PostCategory.resource: AppColors.aiAccent,
  };

  static const _catLabels = {
    PostCategory.general: 'General',
    PostCategory.technology: 'Technology',
    PostCategory.project: 'Project',
    PostCategory.announcement: 'Announcement',
    PostCategory.resource: 'Resource',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = _catColors[post.category] ?? AppColors.textMuted;
    final catLabel = _catLabels[post.category] ?? '';

    return GlassCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.aiAccent],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Text(
                    post.authorInitials,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      _timeAgo(post.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(catLabel, style: TextStyle(fontSize: 10, color: catColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(post.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (post.resourceUrl != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.link, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    post.resourceUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LikeButton(post: post),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.chat_bubble_outline, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${post.replyCount}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.post});
  final CommunityPostEntity post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await ref.read(communityRepositoryProvider).toggleLike(post.id);
        ref.invalidate(communityPostsProvider);
      },
      child: Row(
        children: [
          Icon(
            post.isLiked ? Icons.favorite : Icons.favorite_border,
            size: 15,
            color: post.isLiked ? AppColors.danger : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.likeCount}',
            style: TextStyle(
              fontSize: 12,
              color: post.isLiked ? AppColors.danger : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// New post FAB
// ─────────────────────────────────────────────────────────────
class _NewPostButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showNewPostSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          gradient: AppColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text('Post', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showNewPostSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewPostSheet(onSubmit: (title, content, cat, url) async {
        await ref.read(communityRepositoryProvider).createPost(
              title: title,
              content: content,
              category: cat,
              resourceUrl: url.isEmpty ? null : url,
            );
        ref.invalidate(communityPostsProvider);
      }),
    );
  }
}

class _NewPostSheet extends StatefulWidget {
  const _NewPostSheet({required this.onSubmit});
  final Future<void> Function(String title, String content, PostCategory category, String url) onSubmit;

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  PostCategory _cat = PostCategory.general;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.2)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Post', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Title'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'What\'s on your mind?'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(hintText: 'Resource URL (optional)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<PostCategory>(
            value: _cat,
            decoration: const InputDecoration(labelText: 'Category'),
            dropdownColor: AppColors.bgMid,
            items: PostCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name.capitalize())))
                .toList(),
            onChanged: (v) => setState(() => _cat = v!),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : () async {
                if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
                setState(() => _submitting = true);
                await widget.onSubmit(_titleCtrl.text.trim(), _contentCtrl.text.trim(), _cat, _urlCtrl.text.trim());
                if (context.mounted) Navigator.pop(context);
              },
              child: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

extension _StringCapitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
