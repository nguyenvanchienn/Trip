import 'package:tourn/models/post_model.dart';

abstract class PostRepository {
  /// Seed sample posts into data store if it's empty. Used for development.
  Future<void> seedSamplePostsIfEmpty();

  /// Retrieve a post by its identifier (may return null if not found).
  Future<PostModel?> getPostById(String postId);

  // the interface can be expanded if other methods are used via the
  // abstract type; the concrete implementation already provides many
  // helpers for likes/comments/etc.
}
