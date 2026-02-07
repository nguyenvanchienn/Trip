import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_post_card.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';

class HashtagPostsPage extends StatelessWidget {
  final String hashtag;
  final List<Map<String, dynamic>> posts;

  const HashtagPostsPage({
    super.key,
    required this.hashtag,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hashtag), elevation: 0),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final post = posts[index];
          return CommunityPostCard(
            post: post,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Baiviet(post: post, relatedPosts: posts),
                ),
              );
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: posts.length,
      ),
    );
  }
}
