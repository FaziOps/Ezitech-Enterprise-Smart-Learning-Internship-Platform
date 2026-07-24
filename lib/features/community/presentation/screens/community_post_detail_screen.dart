import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/community_providers.dart';

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  const CommunityPostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends ConsumerState<CommunityPostDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    await ref.read(communityRepositoryProvider).createReply(
          postId: widget.postId,
          content: _replyCtrl.text.trim(),
        );
    _replyCtrl.clear();
    ref.invalidate(communityRepliesProvider(widget.postId));
    ref.invalidate(communityPostsProvider);
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityPostsProvider(null));
    final repliesAsync = ref.watch(communityRepliesProvider(widget.postId));

    final post = postsAsync.valueOrNull?.where((p) => p.id == widget.postId).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Discussion'),
      ),
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 120),
              children: [
                // Original post
                GlassContainer(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.aiAccent]),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Center(
                              child: Text(
                                post.authorInitials,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  _timeAgo(post.createdAt),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(post.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(post.content, style: const TextStyle(color: AppColors.textSecondary)),
                      if (post.resourceUrl != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(Icons.link, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.resourceUrl!,
                                style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await ref.read(communityRepositoryProvider).toggleLike(post.id);
                              ref.invalidate(communityPostsProvider);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 16,
                                  color: post.isLiked ? AppColors.danger : AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.likeCount} likes',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${post.replyCount} replies',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Replies', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                // Replies
                repliesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e', style: const TextStyle(color: AppColors.danger)),
                  data: (replies) => replies.isEmpty
                      ? const GlassContainer(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No replies yet. Be the first to respond!',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (final r in replies) ...[
                              _ReplyCard(reply: r),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                ),
              ],
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        color: AppColors.bgMid,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                decoration: const InputDecoration(hintText: 'Write a reply…'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Send reply',
              icon: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: AppColors.primary),
              onPressed: _submitting ? null : _submitReply,
            ),
          ],
        ),
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

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.reply});
  final CommunityReplyEntity reply;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.glassFillStrong,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Center(
              child: Text(
                reply.authorInitials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(reply.authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _timeAgo(reply.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(reply.content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
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
