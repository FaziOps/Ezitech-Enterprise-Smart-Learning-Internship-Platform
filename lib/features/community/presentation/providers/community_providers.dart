import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (_) => CommunityRepositoryImpl(),
);

final communityPostsProvider = FutureProvider.family<List<CommunityPostEntity>, PostCategory?>(
  (ref, category) async {
    final result = await ref.watch(communityRepositoryProvider).getPosts(category: category);
    return result.fold((f) => <CommunityPostEntity>[], (v) => v);
  },
);

final communityRepliesProvider = FutureProvider.family<List<CommunityReplyEntity>, String>(
  (ref, postId) async {
    final result = await ref.watch(communityRepositoryProvider).getReplies(postId);
    return result.fold((f) => <CommunityReplyEntity>[], (v) => v);
  },
);

/// Tracks which category filter is active on the Community screen.
final communityFilterProvider = StateProvider<PostCategory?>((ref) => null);
