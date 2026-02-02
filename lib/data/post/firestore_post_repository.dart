import 'package:tourn/domain/post_repository/post_repository.dart';

/// Minimal Firestore implementation stub for PostRepository to satisfy compilation.
class FirestorePostRepository implements PostRepository {
  @override
  Future<void> seedSamplePostsIfEmpty() async {
    // TODO: Implement real Firestore seeding. Stub is no-op for now.
    return;
  }
}
