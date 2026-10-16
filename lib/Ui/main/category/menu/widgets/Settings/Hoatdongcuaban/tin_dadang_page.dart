import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị các tin (stories) đã đăng
class TinDaDangPage extends StatefulWidget {
  const TinDaDangPage({super.key});

  @override
  State<TinDaDangPage> createState() => _TinDaDangPageState();
}

class _TinDaDangPageState extends State<TinDaDangPage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<ActivityItem> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final stories = await _activityService.getMyStories(limit: 50);

    if (mounted) {
      setState(() {
        _stories = stories;
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin'), centerTitle: true, elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tin nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tin của bạn sẽ xuất hiện ở đây',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final story = _stories[index];
                  final isExpired = story.metadata?['isExpired'] ?? false;
                  final viewCount = story.metadata?['viewCount'] ?? 0;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: story.postPhotoUrl != null
                            ? Image.network(
                                story.postPhotoUrl!,
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
                                ).colorScheme.primary.withOpacity(0.2),
                                child: Center(
                                  child: Text(
                                    story.content,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                      ),

                      // Expired overlay
                      if (isExpired)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Center(
                            child: Text(
                              'Đã hết hạn',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      // Info overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                viewCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(story.timestamp),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
