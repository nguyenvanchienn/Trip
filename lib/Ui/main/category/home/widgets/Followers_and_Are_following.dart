import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/Profile.dart';
import 'package:tourn/Ui/main/category/mail/pages/ChatPage.dart';

class FollowersAndAreFollowing extends StatefulWidget {
  final int initialTabIndex;

  const FollowersAndAreFollowing({super.key, this.initialTabIndex = 0});

  @override
  State<FollowersAndAreFollowing> createState() =>
      _FollowersAndAreFollowingState();
}

class _FollowersAndAreFollowingState extends State<FollowersAndAreFollowing>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Dữ liệu mẫu cho tác giả
  final List<Map<String, dynamic>> author = [
    {'name': 'Nguyễn Chiến'},
  ];

  // Dữ liệu mẫu cho người theo dõi
  final List<Map<String, dynamic>> _followers = [
    {
      'name': 'Nguyễn Văn An',
      'username': '@nguyenvanan',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
    {
      'name': 'Trần Thị Bình',
      'username': '@tranthibinh',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': false,
    },
    {
      'name': 'Lê Minh Châu',
      'username': '@leminhchau',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
    {
      'name': 'Phạm Đức Dũng',
      'username': '@phamducdung',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': false,
    },
    {
      'name': 'Hoàng Thu Hà',
      'username': '@hoangthuha',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
  ];

  // Dữ liệu mẫu cho đang theo dõi
  final List<Map<String, dynamic>> _following = [
    {
      'name': 'Võ Quốc Khánh',
      'username': '@voquockhanh',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
    {
      'name': 'Đặng Thùy Linh',
      'username': '@dangthuylinh',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
    {
      'name': 'Bùi Thanh Mai',
      'username': '@buithanhmai',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
    {
      'name': 'Ngô Hải Nam',
      'username': '@ngohainam',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
  ];

  // Dữ liệu mẫu cho bạn bè
  final List<Map<String, dynamic>> _friends = [
    {
      'name': 'Nguyễn Văn An',
      'username': '@nguyenvanan',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
    {
      'name': 'Lê Minh Châu',
      'username': '@leminhchau',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
    {
      'name': 'Hoàng Thu Hà',
      'username': '@hoangthuha',
      'avatar': 'asset/images/OIP.jpg',
      'isFollowing': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          author[0]['name'] as String, // Hiển thị tên tác giả
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF113953),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF113953),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: [
            Tab(text: 'Người theo dõi (${_followers.length})'),
            Tab(text: 'Đang theo dõi (${_following.length})'),
            Tab(text: 'Bạn bè (${_friends.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followers, isFollowerTab: true),
          _buildUserList(_following, isFollowingTab: true),
          _buildUserList(_friends, isFriendTab: true),
        ],
      ),
    );
  }

  Widget _buildUserList(
    List<Map<String, dynamic>> users, {
    bool isFollowerTab = false,
    bool isFollowingTab = false,
    bool isFriendTab = false,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowerTab
                  ? Icons.people_outline
                  : isFollowingTab
                  ? Icons.person_add_alt_1_outlined
                  : Icons.group_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isFollowerTab
                  ? 'Chưa có người theo dõi'
                  : isFollowingTab
                  ? 'Bạn chưa theo dõi ai'
                  : 'Chưa có bạn bè',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserItem(
          user,
          isFollowerTab: isFollowerTab,
          isFollowingTab: isFollowingTab,
          isFriendTab: isFriendTab,
        );
      },
    );
  }

  Widget _buildUserItem(
    Map<String, dynamic> user, {
    bool isFollowerTab = false,
    bool isFollowingTab = false,
    bool isFriendTab = false,
  }) {
    return InkWell(
      onTap: () {
        // Điều hướng đến trang profile của người dùng
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => profile()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    user['avatar'] as String,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                if (isFriendTab)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Thông tin người dùng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113953),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['username'] as String,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Nút hành động
            _buildActionButton(
              user,
              isFollowerTab,
              isFollowingTab,
              isFriendTab,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    Map<String, dynamic> user,
    bool isFollowerTab,
    bool isFollowingTab,
    bool isFriendTab,
  ) {
    final bool isFollowing = user['isFollowing'] as bool;

    if (isFriendTab) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              // Mở chat với bạn bè - sử dụng rootNavigator để ẩn bottom nav bar
              Navigator.of(
                context,
                rootNavigator: true,
              ).push(MaterialPageRoute(builder: (context) => const ChatPage()));
            },
            icon: const Icon(Icons.chat_bubble_outline),
            color: const Color(0xFF113953),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'unfriend') {
                _showUnfriendDialog(user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'unfriend',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hủy kết bạn'),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (isFollowingTab) {
      return ElevatedButton(
        onPressed: () {
          _showUnfollowDialog(user);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Đang theo dõi'),
      );
    }

    // Tab người theo dõi
    return ElevatedButton(
      onPressed: () {
        setState(() {
          user['isFollowing'] = !isFollowing;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing
            ? Colors.grey[200]
            : const Color(0xFF113953),
        foregroundColor: isFollowing ? Colors.black87 : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi lại'),
    );
  }

  void _showUnfollowDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ theo dõi'),
        content: Text('Bạn có chắc muốn bỏ theo dõi ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _following.remove(user);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã bỏ theo dõi ${user['name']}')),
              );
            },
            child: const Text(
              'Bỏ theo dõi',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnfriendDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text('Bạn có chắc muốn hủy kết bạn với ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _friends.remove(user);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã hủy kết bạn với ${user['name']}')),
              );
            },
            child: const Text(
              'Hủy kết bạn',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
