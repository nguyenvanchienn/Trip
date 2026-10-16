import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';

class KhoLuuTruPage extends StatefulWidget {
  const KhoLuuTruPage({super.key});

  @override
  State<KhoLuuTruPage> createState() => _KhoLuuTruPageState();
}

class _KhoLuuTruPageState extends State<KhoLuuTruPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Bài viết', 'Địa điểm', 'Ghi chú'];

  // Firebase services
  final FirebaseActivityService _activityService = FirebaseActivityService();
  final FirestorePostRepository _postRepository = FirestorePostRepository();

  // Saved posts from Firebase
  List<PostModel> _savedPosts = [];
  bool _loadingPosts = true;

  final Map<String, List<Map<String, dynamic>>> _items = {
    'Địa điểm': [],
    'Ghi chú': [],
  };
  final Map<String, List<Map<String, dynamic>>> _filtered = {
    'Địa điểm': [],
    'Ghi chú': [],
  };

  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAll();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final activities = await _activityService.getSavedPosts(limit: 100);
      final posts = <PostModel>[];

      for (final activity in activities) {
        if (activity.postId != null) {
          try {
            final post = await _postRepository.getPostById(activity.postId!);
            if (post != null) {
              posts.add(post);
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _savedPosts = posts;
          _loadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPosts = false);
      }
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    // Only load local storage tabs (not 'Bài viết' which is from Firebase)
    final localTabs = _tabs.where((t) => t != 'Bài viết').toList();
    for (final tab in localTabs) {
      final raw = prefs.getStringList('storage_$tab') ?? [];
      final list = raw
          .map((s) {
            try {
              final d = jsonDecode(s);
              if (d is Map<String, dynamic>) return d;
              if (d is Map) return Map<String, dynamic>.from(d);
              return <String, dynamic>{};
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((m) => m.isNotEmpty)
          .toList();
      _items[tab] = list;
      _filtered[tab] = List.from(list.reversed);
    }
    setState(() => _loading = false);
  }

  Future<void> _saveTab(String tab) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items[tab]!.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('storage_$tab', raw);
  }

  void _applyFilter(String tab, String q) {
    _query = q;
    final low = q.trim().toLowerCase();
    final base = _items[tab] ?? [];
    if (low.isEmpty) {
      _filtered[tab] = List.from(base.reversed);
    } else {
      _filtered[tab] = base.reversed.where((m) {
        final title = (m['title'] ?? '').toString().toLowerCase();
        final desc = (m['desc'] ?? '').toString().toLowerCase();
        return title.contains(low) || desc.contains(low);
      }).toList();
    }
    setState(() {});
  }

  Future<void> _addItem(String tab) async {
    final res = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (c) {
        final titleCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        return AlertDialog(
          title: Text('Thêm vào $tab'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: 'Tiêu đề'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(hintText: 'Mô tả'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(null),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final t = titleCtrl.text.trim();
                if (t.isEmpty) return; // ignore empty
                Navigator.of(c).pop({
                  'id': DateTime.now().microsecondsSinceEpoch.toString(),
                  'title': t,
                  'desc': descCtrl.text.trim(),
                  'createdAt': DateTime.now().toIso8601String(),
                });
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

    if (res != null) {
      _items[tab] ??= [];
      _items[tab]!.add(res);
      await _saveTab(tab);
      _applyFilter(tab, _query);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã thêm')));
    }
  }

  Future<void> _deleteItem(String tab, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa mục'),
        content: const Text('Bạn có chắc muốn xóa mục này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      _items[tab]!.removeWhere((m) => m['id'] == id);
      await _saveTab(tab);
      _applyFilter(tab, _query);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSavedPostsTab() {
    if (_savedPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có bài viết đã lưu',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _savedPosts.length,
      itemBuilder: (context, index) {
        final post = _savedPosts[index];
        return _buildSavedPostCard(post);
      },
    );
  }

  Widget _buildSavedPostCard(PostModel post) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => Baiviet(postId: post.id)));
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Thumbnail
            if (post.mediaUrls.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  post.mediaUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.article,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            // Content overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.content.length > 50
                          ? '${post.content.substring(0, 50)}...'
                          : post.content,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${post.likes}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Unsave button
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.bookmark, color: Colors.orange),
                onPressed: () => _unsavePost(post),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unsavePost(PostModel post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bỏ lưu bài viết'),
        content: const Text('Bạn có chắc muốn bỏ lưu bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Bỏ lưu'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseActivityService().unsavePost(post.id);
      setState(() {
        _savedPosts.removeWhere((p) => p.id == post.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã bỏ lưu bài viết')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_tabController.index];
    final isSavedPostsTab = currentTab == 'Bài viết';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho lưu trữ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
        actions: [
          if (!isSavedPostsTab)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final q = await showSearch<String>(
                  context: context,
                  delegate: _StorageSearchDelegate(_items[currentTab] ?? []),
                );
                if (q != null) _applyFilter(currentTab, q);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSavedPosts();
              _loadAll();
            },
          ),
        ],
      ),
      floatingActionButton: isSavedPostsTab
          ? null
          : FloatingActionButton(
              onPressed: () => _addItem(currentTab),
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                // Special handling for saved posts tab
                if (tab == 'Bài viết') {
                  return _buildSavedPostsTab();
                }

                final list = _filtered[tab] ?? [];
                return list.isEmpty
                    ? Center(child: Text('Không có mục trong $tab'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = list[i];
                          return Card(
                            child: ListTile(
                              title: Text(item['title'] ?? ''),
                              subtitle: Text((item['desc'] ?? '').toString()),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteItem(tab, item['id']),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StorageDetailPage(item: item),
                                ),
                              ),
                            ),
                          );
                        },
                      );
              }).toList(),
            ),
    );
  }
}

class StorageDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const StorageDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item['title'] ?? '')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['desc'] ?? ''),
            const SizedBox(height: 12),
            Text(
              'Tạo: ${item['createdAt'] ?? ''}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> items;
  _StorageSearchDelegate(this.items);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim().toLowerCase();
    final res = items
        .where(
          (m) =>
              (m['title'] ?? '').toString().toLowerCase().contains(q) ||
              (m['desc'] ?? '').toString().toLowerCase().contains(q),
        )
        .toList();
    return ListView.builder(
      itemCount: res.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(res[i]['title']),
        subtitle: Text((res[i]['desc'] ?? '')),
        onTap: () => close(context, query),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim().toLowerCase();
    final suggestions = q.isEmpty
        ? []
        : items
              .where(
                (m) =>
                    (m['title'] ?? '').toString().toLowerCase().contains(q) ||
                    (m['desc'] ?? '').toString().toLowerCase().contains(q),
              )
              .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(suggestions[i]['title']),
        subtitle: Text((suggestions[i]['desc'] ?? '')),
        onTap: () {
          query = suggestions[i]['title'];
          showResults(context);
        },
      ),
    );
  }
}
