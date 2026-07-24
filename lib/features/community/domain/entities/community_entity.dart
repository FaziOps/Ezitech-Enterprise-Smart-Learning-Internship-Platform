import 'package:equatable/equatable.dart';

enum PostCategory { general, technology, project, announcement, resource }

class CommunityPostEntity extends Equatable {
  const CommunityPostEntity({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.likeCount,
    required this.replyCount,
    required this.isLiked,
    this.resourceUrl,
  });

  final String id;
  final String authorName;
  final String authorInitials;
  final String title;
  final String content;
  final PostCategory category;
  final DateTime createdAt;
  final int likeCount;
  final int replyCount;
  final bool isLiked;
  final String? resourceUrl;

  CommunityPostEntity copyWith({bool? isLiked, int? likeCount}) =>
      CommunityPostEntity(
        id: id,
        authorName: authorName,
        authorInitials: authorInitials,
        title: title,
        content: content,
        category: category,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        replyCount: replyCount,
        isLiked: isLiked ?? this.isLiked,
        resourceUrl: resourceUrl,
      );

  @override
  List<Object?> get props => [id, authorName, title, content, category, createdAt, likeCount, replyCount, isLiked, resourceUrl];
}

class CommunityReplyEntity extends Equatable {
  const CommunityReplyEntity({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.authorInitials,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorName;
  final String authorInitials;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, postId, authorName, content, createdAt];
}
