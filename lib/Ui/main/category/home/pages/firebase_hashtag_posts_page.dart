import 'package:flutter/material.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/Ui/main/category/home/pages/FirebaseNewfeed.dart';

class FirebaseHashtagPostsPage extends StatelessWidget {
  final String hashtag;
  final PostModel selectedPost;

  const FirebaseHashtagPostsPage({
    super.key,
    required this.hashtag,
    required this.selectedPost,
  });

  @override
  Widget build(BuildContext context) {
    final postRepo = FirestorePostRepository();

    // Use different stream based on hashtag type
    Stream<List<PostModel>> postsStream;
    if (hashtag == 'Khác') {
      // Get posts without hashtags but with experience sharing enabled
      postsStream = postRepo
          .getPublicFeed(limit: 50)
          .map(
            (posts) => posts
                .where(
                  (p) => p.hashtags.isEmpty && p.experienceEntries.isNotEmpty,
                )
                .toList(),
          );
    } else {
      postsStream = postRepo.getPostsByHashtag(hashtag);
    }

    return Scaffold(
      appBar: AppBar(title: Text(hashtag), elevation: 0),
      body: StreamBuilder<List<PostModel>>(
        stream: postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final posts = snapshot.data ?? [];

          // ensure selectedPost appears first
          final ordered = [selectedPost];
          for (var p in posts) {
            if (p.id != selectedPost.id) ordered.add(p);
          }

          if (ordered.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Không có bài viết nào'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: ordered.length,
            itemBuilder: (context, index) {
              final post = ordered[index];
              return FirebasePostCard(post: post);
            },
          );
        },
      ),
    );
  }
}
