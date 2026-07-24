import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/failure.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl();

  final _uuid = const Uuid();
  static const _boxName = 'community_box';

  Box get _box => Hive.box(_boxName);
  static Future<void> openBox() async => Hive.openBox(_boxName);

  // ──────────────────────────────────────────────
  // Seeds — realistic mock data shown until backend is live
  // ──────────────────────────────────────────────
  static List<Map<String, dynamic>> _seedPosts() {
    final now = DateTime.now();
    return [
      {
        'id': 'p1',
        'author_name': 'Ayesha Raza',
        'author_initials': 'AR',
        'title': 'Clean Architecture Tips for Flutter',
        'content':
            "After Week 2, one thing became clear: keeping domain entities free of any Flutter/third-party imports makes unit testing trivial. Here's a quick pattern I use for every use case...",
        'category': 'technology',
        'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'like_count': 14,
        'reply_count': 3,
        'is_liked': false,
        'resource_url': null,
      },
      {
        'id': 'p2',
        'author_name': 'Ezitech Faculty',
        'author_initials': 'EF',
        'title': 'Week 3 Milestone — Offline Sync Evaluation',
        'content':
            'All interns: your offline sync implementation will be evaluated on Friday. Make sure your outbox queue handles reconnect without duplicates. See the rubric attached.',
        'category': 'announcement',
        'created_at': now.subtract(const Duration(hours: 10)).toIso8601String(),
        'like_count': 27,
        'reply_count': 8,
        'is_liked': true,
        'resource_url': 'https://ezitech.example.com/rubric/week3',
      },
      {
        'id': 'p3',
        'author_name': 'Hassan Ali',
        'author_initials': 'HA',
        'title': 'Flutter UI Resources — Glassmorphism',
        'content':
            "Sharing a Figma kit I found that matches our app's glassmorphism style. Useful for planning screens before coding. Link below 👇",
        'category': 'resource',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'like_count': 9,
        'reply_count': 2,
        'is_liked': false,
        'resource_url': 'https://www.figma.com/community/glassmorphism',
      },
      {
        'id': 'p4',
        'author_name': 'Zainab Siddiqui',
        'author_initials': 'ZS',
        'title': 'Looking for a partner for the Project Collaboration bonus',
        'content':
            "I'm working on the PiP video bonus challenge and would love to pair up. My area is media/video. Anyone interested in teaming up on the bonus challenges?",
        'category': 'project',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'like_count': 5,
        'reply_count': 4,
        'is_liked': false,
        'resource_url': null,
      },
      {
        'id': 'p5',
        'author_name': 'Omar Farooq',
        'author_initials': 'OF',
        'title': 'General Check-in — How is Week 3 going?',
        'content':
            'Checking in with everyone. How are you finding the offline-first implementation? Any blockers? Drop your status below.',
        'category': 'general',
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'like_count': 11,
        'reply_count': 6,
        'is_liked': false,
        'resource_url': null,
      },
    ];
  }

  static Map<String, List<Map<String, dynamic>>> _seedReplies() {
    final now = DateTime.now();
    return {
      'p1': [
        {
          'id': 'r1a',
          'post_id': 'p1',
          'author_name': 'Hassan Ali',
          'author_initials': 'HA',
          'content': "Great tip! I've been mixing repository concerns into my use cases — will refactor now.",
          'created_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
        },
        {
          'id': 'r1b',
          'post_id': 'p1',
          'author_name': 'Zainab Siddiqui',
          'author_initials': 'ZS',
          'content': "Same. What's your approach for error handling in use cases?",
          'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
        },
      ],
      'p2': [
        {
          'id': 'r2a',
          'post_id': 'p2',
          'author_name': 'Omar Farooq',
          'author_initials': 'OF',
          'content': 'Just confirmed mine handles it. Used idempotent submission IDs on every outbox item.',
          'created_at': now.subtract(const Duration(hours: 8)).toIso8601String(),
        },
      ],
    };
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────
  List<Map<String, dynamic>> _storedPosts() {
    final raw = _box.get('posts') as List?;
    if (raw == null || raw.isEmpty) return _seedPosts();
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, List<Map<String, dynamic>>> _storedReplies() {
    final raw = _box.get('replies') as Map?;
    if (raw == null) return _seedReplies();
    return raw.map((k, v) => MapEntry(
          k as String,
          (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        ));
  }

  CommunityPostEntity _postFromMap(Map<String, dynamic> m) => CommunityPostEntity(
        id: m['id'] as String,
        authorName: m['author_name'] as String,
        authorInitials: m['author_initials'] as String,
        title: m['title'] as String,
        content: m['content'] as String,
        category: PostCategory.values.firstWhere((c) => c.name == m['category'], orElse: () => PostCategory.general),
        createdAt: DateTime.parse(m['created_at'] as String),
        likeCount: m['like_count'] as int,
        replyCount: m['reply_count'] as int,
        isLiked: m['is_liked'] as bool,
        resourceUrl: m['resource_url'] as String?,
      );

  CommunityReplyEntity _replyFromMap(Map<String, dynamic> m) => CommunityReplyEntity(
        id: m['id'] as String,
        postId: m['post_id'] as String,
        authorName: m['author_name'] as String,
        authorInitials: m['author_initials'] as String,
        content: m['content'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  // ──────────────────────────────────────────────
  // Repository API
  // ──────────────────────────────────────────────
  @override
  Future<Result<List<CommunityPostEntity>>> getPosts({PostCategory? category}) async {
    try {
      final posts = _storedPosts().map(_postFromMap).toList();
      final filtered = category == null ? posts : posts.where((p) => p.category == category).toList();
      // Sort newest first
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Result.success(filtered);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to load posts: $e'));
    }
  }

  @override
  Future<Result<List<CommunityReplyEntity>>> getReplies(String postId) async {
    try {
      final all = _storedReplies();
      final replies = (all[postId] ?? []).map(_replyFromMap).toList();
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return Result.success(replies);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to load replies: $e'));
    }
  }

  @override
  Future<Result<CommunityPostEntity>> createPost({
    required String title,
    required String content,
    required PostCategory category,
    String? resourceUrl,
  }) async {
    try {
      final posts = _storedPosts();
      final newPost = {
        'id': _uuid.v4(),
        'author_name': 'You',
        'author_initials': 'ME',
        'title': title,
        'content': content,
        'category': category.name,
        'created_at': DateTime.now().toIso8601String(),
        'like_count': 0,
        'reply_count': 0,
        'is_liked': false,
        'resource_url': resourceUrl,
      };
      posts.insert(0, newPost);
      await _box.put('posts', posts);
      return Result.success(_postFromMap(newPost));
    } catch (e) {
      return Result.failure(CacheFailure('Failed to create post: $e'));
    }
  }

  @override
  Future<Result<CommunityReplyEntity>> createReply({
    required String postId,
    required String content,
  }) async {
    try {
      final replies = _storedReplies();
      final newReply = {
        'id': _uuid.v4(),
        'post_id': postId,
        'author_name': 'You',
        'author_initials': 'ME',
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      };
      replies[postId] = [...(replies[postId] ?? []), newReply];
      await _box.put('replies', replies);

      // bump reply count on post
      final posts = _storedPosts();
      final idx = posts.indexWhere((p) => p['id'] == postId);
      if (idx != -1) {
        posts[idx] = {...posts[idx], 'reply_count': (posts[idx]['reply_count'] as int) + 1};
        await _box.put('posts', posts);
      }
      return Result.success(_replyFromMap(newReply));
    } catch (e) {
      return Result.failure(CacheFailure('Failed to create reply: $e'));
    }
  }

  @override
  Future<Result<void>> toggleLike(String postId) async {
    try {
      final posts = _storedPosts();
      final idx = posts.indexWhere((p) => p['id'] == postId);
      if (idx == -1) return Result.success(null);
      final post = Map<String, dynamic>.from(posts[idx]);
      final liked = post['is_liked'] as bool;
      post['is_liked'] = !liked;
      post['like_count'] = (post['like_count'] as int) + (liked ? -1 : 1);
      posts[idx] = post;
      await _box.put('posts', posts);
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to toggle like: $e'));
    }
  }
}
