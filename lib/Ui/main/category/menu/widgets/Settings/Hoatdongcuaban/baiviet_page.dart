import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị các bài viết của người dùng
class BaivietPage extends StatefulWidget {
  const BaivietPage({super.key});

  @override
  State<BaivietPage> createState() => _BaivietPageState();
}

class _BaivietPageState extends State<BaivietPage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<ActivityItem> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final posts = await _activityService.getMyPosts(limit: 50);

    if (mounted) {
      setState(() {
        _posts = posts;
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Show sort options
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài viết nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bài viết của bạn sẽ xuất hiện ở đây',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final likeCount = post.metadata?['likeCount'] ?? 0;
                  final commentCount = post.metadata?['commentCount'] ?? 0;

                  return GestureDetector(
                    onTap: () {
                      // Navigate to post detail
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail
                        post.postPhotoUrl != null
                            ? Image.network(
                                post.postPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  post.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),

                        // Stats overlay (shown on hover/tap)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  likeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.comment,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  commentCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
