import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/community_post_card.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';

class CommunityAllPostsPage extends StatelessWidget {
  final List<Map<String, dynamic>> posts;

  const CommunityAllPostsPage({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinh nghiệm từ cộng đồng'),
        elevation: 0,
      ),
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
