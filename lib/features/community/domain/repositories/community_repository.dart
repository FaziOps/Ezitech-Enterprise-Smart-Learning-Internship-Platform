import '../../../../core/utils/failure.dart';
import '../entities/community_entity.dart';

abstract interface class CommunityRepository {
  Future<Result<List<CommunityPostEntity>>> getPosts({PostCategory? category});
  Future<Result<List<CommunityReplyEntity>>> getReplies(String postId);
  Future<Result<CommunityPostEntity>> createPost({
    required String title,
    required String content,
    required PostCategory category,
    String? resourceUrl,
  });
  Future<Result<CommunityReplyEntity>> createReply({
    required String postId,
    required String content,
  });
  Future<Result<void>> toggleLike(String postId);
}
