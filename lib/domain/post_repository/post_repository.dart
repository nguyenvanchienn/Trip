abstract class PostRepository {
  /// Seed sample posts into data store if it's empty. Used for development.
  Future<void> seedSamplePostsIfEmpty();
}
