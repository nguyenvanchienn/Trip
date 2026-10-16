import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị bình luận và tương tác của người dùng
class BinhluanVaTuongtacPage extends StatefulWidget {
  const BinhluanVaTuongtacPage({super.key});

  @override
  State<BinhluanVaTuongtacPage> createState() => _BinhluanVaTuongtacPageState();
}

class _BinhluanVaTuongtacPageState extends State<BinhluanVaTuongtacPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseActivityService _activityService = FirebaseActivityService();

  List<ActivityItem> _comments = [];
  List<ActivityItem> _likes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final comments = await _activityService.getMyComments(limit: 50);
    final likes = await _activityService.getMyLikes(limit: 50);

    if (mounted) {
      setState(() {
        _comments = comments;
        _likes = likes;
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

  Widget _buildActivityTile(ActivityItem item) {
    final isComment = item.type == 'comment';

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isComment ? Icons.comment_outlined : Icons.favorite_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _formatDate(item.timestamp),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: item.postPhotoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.postPhotoUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            )
          : null,
      onTap: () {
        // Navigate to post detail
      },
    );
  }

  Widget _buildCommentsList() {
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có bình luận nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) => _buildActivityTile(_comments[index]),
    );
  }

  Widget _buildLikesList() {
    if (_likes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có lượt thích nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _likes.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) => _buildActivityTile(_likes[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bình luận và tương tác'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bình luận'),
            Tab(text: 'Lượt thích'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildCommentsList(),
                ),
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildLikesList(),
                ),
              ],
            ),
    );
  }
}
