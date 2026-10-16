import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/domain/post_repository/post_repository.dart';
import 'package:tourn/data/firebase/firebase_post_service.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/models/comment_model.dart';

/// Full Firestore implementation for PostRepository
class FirestorePostRepository implements PostRepository {
  // Singleton pattern để share cache giữa các instances
  static final FirestorePostRepository _instance =
      FirestorePostRepository._internal();
  factory FirestorePostRepository() => _instance;
  FirestorePostRepository._internal();

  final FirebasePostService _postService = FirebasePostService();

  // Get current user ID for local checks
  String? get currentUserId => _postService.currentUserId;

  @override
  Future<void> seedSamplePostsIfEmpty() async {
    try {
      // Add timeout to prevent hanging
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[PostRepo] seedSamplePostsIfEmpty timed out');
              throw TimeoutException('Firestore query timed out');
            },
          );
      if (snapshot.docs.isEmpty) {
        // Seed some sample posts for development
        await _postService.createPost(
          content: 'Chào mừng đến với Trip! Đây là bài viết mẫu đầu tiên.',
          authorName: 'Trip Admin',
          audience: PostAudience.public,
        );
      }
    } catch (e) {
      // Silently fail - this is just for development seeding
      print('[PostRepo] seedSamplePostsIfEmpty error: $e');
    }
  }

  // Create post with optional media
  Future<PostModel?> createPost({
    required String content,
    required String authorName,
    String? authorPhotoUrl,
    List<Uint8List>? mediaBytes,
    String? backgroundColor,
    PostAudience audience = PostAudience.public,
    String? location,
    String? tripId,
    List<String>? hashtags,
    int layoutIndex = 0,
    List<Map<String, dynamic>>? experienceEntries,
  }) async {
    return _postService.createPost(
      content: content,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      mediaBytes: mediaBytes,
      backgroundColor: backgroundColor,
      audience: audience,
      location: location,
      tripId: tripId,
      hashtags: hashtags,
      layoutIndex: layoutIndex,
      experienceEntries: experienceEntries,
    );
  }

  // Get post by ID
  @override
  Future<PostModel?> getPostById(String postId) async {
    return _postService.getPostById(postId);
  }

  // Update post
  Future<void> updatePost(PostModel post) async {
    return _postService.updatePost(post);
  }

  /// Pin or unpin a post for the current user.  When pinning a post,
  /// any previously pinned posts by the same author are unpinned first.
  Future<void> pinPost(String postId, {required bool pinned}) async {
    // delegate to service, which handles the one-at-a-time rule
    return _postService.pinPost(postId, pinned: pinned);
  }

  /// Change whether comments are allowed on a post.
  Future<void> setAllowComments(String postId, bool allow) async {
    final post = await getPostById(postId);
    if (post != null) {
      await updatePost(post.copyWith(allowComments: allow));
    }
  }

  /// Add post to album list stored on the post document
  Future<void> addPostToAlbum(String postId, String albumId) async {
    final post = await getPostById(postId);
    if (post != null) {
      final existing = List<String>.from(post.albumIds);
      if (!existing.contains(albumId)) {
        existing.add(albumId);
        await updatePost(post.copyWith(albumIds: existing));
      }
    }
  }

  // Update post audience only
  Future<void> updatePostAudience(String postId, PostAudience audience) async {
    return _postService.updatePostAudience(postId, audience);
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    return _postService.deletePost(postId);
  }

  // Like/Unlike post
  Future<void> likePost(String postId) async {
    return _postService.likePost(postId);
  }

  Future<void> unlikePost(String postId) async {
    return _postService.unlikePost(postId);
  }

  Future<bool> isPostLiked(String postId) async {
    return _postService.isPostLiked(postId);
  }

  // Comments
  Future<CommentModel?> addComment({
    required String postId,
    required String content,
    required String authorName,
    String? authorPhotoUrl,
    String? parentCommentId,
  }) async {
    return _postService.addComment(
      postId: postId,
      content: content,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      parentCommentId: parentCommentId,
    );
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _postService.getComments(postId);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    return _postService.deleteComment(postId, commentId);
  }

  Future<void> likeComment(String postId, String commentId) async {
    return _postService.likeComment(postId, commentId);
  }

  Future<void> unlikeComment(String postId, String commentId) async {
    return _postService.unlikeComment(postId, commentId);
  }

  // Feeds
  final Map<String, List<PostModel>> _userPostsCache = {};

  Stream<List<PostModel>> getFeed(List<String> followingIds) {
    return _postService.getFeed(followingIds);
  }

  Stream<List<PostModel>> getPublicFeed({int limit = 20}) {
    return _postService.getPublicFeed(limit: limit);
  }

  /// Retrieve trending posts ordered by number of likes (descending).
  ///
  /// Since Firestore doesn't support ordering by array length, we simply
  /// fetch a larger public feed and sort locally. The `limit` parameter
  /// determines how many results are returned to the caller.
  Stream<List<PostModel>> getTrendingFeed({int limit = 1}) {
    // fetch more than needed in case we need to pick top by likes
    return getPublicFeed(limit: limit * 5).map((posts) {
      posts.sort(
        (a, b) => b.likes.length.compareTo(a.likes.length),
      ); // most liked first
      return posts.take(limit).toList();
    });
  }

  /// Return posts that include the given hashtag in their list of hashtags.
  Stream<List<PostModel>> getPostsByHashtag(String hashtag, {int limit = 50}) {
    return _postService.getPostsByHashtag(hashtag, limit: limit);
  }

  Stream<List<PostModel>> getUserPosts(String userId, {int limit = 50}) {
    // listen and cache in memory
    return _postService.getUserPosts(userId, limit: limit).map((posts) {
      // repository-level cache should also maintain order
      _userPostsCache[userId] = List<PostModel>.from(posts);
      return posts;
    });
  }

  /// Return only posts that contain a video URL in their mediaUrls list.
  Stream<List<PostModel>> getUserVideoPosts(String userId, {int limit = 50}) {
    // reuse existing user posts stream and filter
    return getUserPosts(userId, limit: limit).map((posts) {
      return posts.where((p) {
        // heuristics copied from UI helper
        return p.mediaUrls.any((url) {
          final lower = url.toLowerCase();
          return lower.endsWith('.mp4') ||
              lower.endsWith('.mov') ||
              lower.endsWith('.webm') ||
              lower.endsWith('.avi') ||
              lower.endsWith('.mkv');
        });
      }).toList();
    });
  }

  List<PostModel>? getCachedUserPosts(String userId) {
    return _userPostsCache[userId];
  }

  // Stream single post
  Stream<PostModel?> streamPost(String postId) {
    return _postService.streamPost(postId);
  }

  // Share post
  Future<void> sharePost(String postId) async {
    return _postService.sharePost(postId);
  }

  /// Tạo bài viết chia sẻ (shared post) - giống Facebook
  /// Tạo một bài viết mới trên profile người dùng với bài viết gốc được nhúng
  Future<PostModel?> createSharedPost({
    required String originalPostId,
    required String authorName,
    String? authorPhotoUrl,
    String content = '',
    PostAudience audience = PostAudience.public,
  }) async {
    return _postService.createSharedPost(
      originalPostId: originalPostId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      audience: audience,
    );
  }

  // Search
  Future<List<PostModel>> searchPosts(String query) async {
    return _postService.searchPosts(query);
  }
}
