import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';

/// Trang hiển thị bộ sưu tập và mục đã lưu
class BosuutapVaDaluuPage extends StatefulWidget {
  const BosuutapVaDaluuPage({super.key});

  @override
  State<BosuutapVaDaluuPage> createState() => _BosuutapVaDaluuPageState();
}

class _BosuutapVaDaluuPageState extends State<BosuutapVaDaluuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseActivityService _activityService = FirebaseActivityService();

  List<ActivityItem> _savedPosts = [];
  List<Map<String, dynamic>> _collections = [];
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

    final saved = await _activityService.getSavedPosts(limit: 50);
    final collections = await _activityService.getCollections();

    if (mounted) {
      setState(() {
        _savedPosts = saved;
        _collections = collections;
        _loading = false;
      });
    }
  }

  Widget _buildSavedGrid() {
    if (_savedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa lưu bài viết nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Các bài viết bạn lưu sẽ hiển thị ở đây',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _savedPosts.length,
      itemBuilder: (context, index) {
        final post = _savedPosts[index];

        return GestureDetector(
          onTap: () {
            // Navigate to post detail
          },
          child: post.postPhotoUrl != null
              ? Image.network(
                  post.postPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                )
              : Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCollectionsList() {
    if (_collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bộ sưu tập nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Create new collection
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo bộ sưu tập'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _collections.length + 1, // +1 for create button
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                // Create new collection
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo bộ sưu tập mới'),
            ),
          );
        }

        final collection = _collections[index - 1];
        final itemCount = (collection['items'] as List?)?.length ?? 0;

        return ListTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: collection['coverUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      collection['coverUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.collections, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.collections, color: Colors.grey),
          ),
          title: Text(
            collection['name'] ?? 'Bộ sưu tập',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('$itemCount mục'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Open collection
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ sưu tập và mục đã lưu'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đã lưu'),
            Tab(text: 'Bộ sưu tập'),
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
                  child: _buildSavedGrid(),
                ),
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildCollectionsList(),
                ),
              ],
            ),
    );
  }
}
