import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/models/post_model.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/home/pages/FirebaseNewfeed.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();
  final FirestorePostRepository _postRepository = FirestorePostRepository();

  bool _editHistory = false;
  bool _isSearching = false;
  List<UserModel> _userResults = [];
  List<PostModel> _postResults = [];
  late TabController _tabController;

  List<String> _searchHistory = [];
  static const String _historyKey = 'search_history';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ctrl.addListener(_onSearchChanged);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    if (mounted) {
      setState(() => _searchHistory = history);
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _searchHistory);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onSearchChanged);
    _ctrl.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _ctrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _userResults = [];
        _postResults = [];
      });
    } else {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    try {
      // Search users by name
      final users = await _userRepository.searchUsers(query);

      // Search posts by content
      final posts = await _postRepository.searchPosts(query);

      if (mounted) {
        setState(() {
          _userResults = users;
          _postResults = posts;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _addToHistory(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
      _saveHistory();
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        _addToHistory(value.trim());
                      },
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm người dùng, bài viết...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() {
                          _userResults = [];
                          _postResults = [];
                          _isSearching = false;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Mới đây",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() => _editHistory = !_editHistory);
              },
              child: Text(
                _editHistory ? 'Xong' : 'Chỉnh sửa',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có lịch sử tìm kiếm',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchHistory.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final text = _searchHistory[i];
        return ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: Text(text),
          trailing: _editHistory
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => _searchHistory.removeAt(i));
                    _saveHistory();
                  },
                )
              : null,
          onTap: () {
            _ctrl.text = text;
            _ctrl.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
            _performSearch(text);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: 'Người dùng (${_userResults.length})'),
            Tab(text: 'Bài viết (${_postResults.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildUserResults(), _buildPostResults()],
          ),
        ),
      ],
    );
  }

  Widget _buildUserResults() {
    if (_userResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _userResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final user = _userResults[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? getImageProvider(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '@${user.username ?? user.uid}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          onTap: () {
            _addToHistory(user.displayName);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => Profile(userId: user.uid)),
            );
          },
        );
      },
    );
  }

  Widget _buildPostResults() {
    if (_postResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy bài viết',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _postResults.length,
      itemBuilder: (_, i) {
        final post = _postResults[i];
        return FirebasePostCard(post: post);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSearchQuery = _ctrl.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            if (!hasSearchQuery) ...[
              _buildEditButton(),
              const Divider(height: 1),
              Expanded(child: _buildHistory()),
            ] else
              Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }
}
