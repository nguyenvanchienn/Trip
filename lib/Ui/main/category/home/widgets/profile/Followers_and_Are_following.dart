import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/messenge/pages/ChatPage.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';

class FollowersAndAreFollowing extends StatefulWidget {
  final int initialTabIndex;
  final String? userId; // Nếu null sẽ dùng current user

  const FollowersAndAreFollowing({
    super.key,
    this.initialTabIndex = 0,
    this.userId,
  });

  @override
  State<FollowersAndAreFollowing> createState() =>
      _FollowersAndAreFollowingState();
}

class _FollowersAndAreFollowingState extends State<FollowersAndAreFollowing>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCommon = false; // hiển thị tab "chung" hay không
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();

  String? _currentUserId;
  String? _targetUserId;
  String _userName = '';

  // dữ liệu người dùng mục tiêu
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  List<UserModel> _friends = [];
  List<UserModel> _followRequests = [];

  // dữ liệu người dùng hiện tại (cần khi hiển thị tab chung)
  List<UserModel> _myFollowers = [];
  List<UserModel> _myFollowing = []; // những người tôi đang theo dõi
  List<UserModel> _myFriends = [];

  // danh sách giao nhau
  List<UserModel> _commonFollowing = [];
  List<UserModel> _commonFriends = [];

  final Map<String, bool> _followsMe =
      {}; // mỗi người theo dõi có đang theo dõi tôi không
  final Map<String, bool> _requestStatus = {}; // request sent by current user
  List<String> _blockedIds = [];

  // theo dõi trạng thái theo dõi cho mỗi người dùng
  final Map<String, bool> _followStatus = {};

  bool _isLoading = true;
  bool _loadingFollowers = true;
  bool _loadingFollowing = true;
  bool _loadingMyFollowers = true;
  bool _loadingMyFollowing = true;
  bool _loadingCommon = true;
  bool _loadingCommonFriends = true;
  bool _loadingFriends = true;
  bool _loadingRequests = true;
  bool _loadError = false;
  bool _showRequests = false;

  bool _ensureSignedIn() {
    if (FirebaseAuth.instance.currentUser != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _targetUserId = widget.userId ?? _currentUserId;
    // chỉ hiển thị tab chung khi xem hồ sơ người khác
    _showCommon = (_targetUserId != null && _targetUserId != _currentUserId);
    _showRequests = _targetUserId != null && _targetUserId == _currentUserId;
    final tabCount = _showCommon
        ? 5
        : (_showRequests
              ? 4
              : 3); // followers, following, friends (+ requests for owner)
    final initIndex = widget.initialTabIndex.clamp(0, tabCount - 1);
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: initIndex,
    );
    _loadData();
    if (_showCommon) _loadMyData();
  }

  Future<void> _loadData() async {
    if (_targetUserId == null) return;

    // tải các id bị chặn để lọc trong mọi danh sách
    _blockedIds = await FirebaseUserService().getBlockedIds();
    FirebaseUserService().blockedIdsStream().listen((ids) {
      if (!mounted) return;
      setState(() {
        _blockedIds = ids;
        _followers = _followers
            .where((u) => !_blockedIds.contains(u.uid))
            .toList();
        _following = _following
            .where((u) => !_blockedIds.contains(u.uid))
            .toList();
        _calculateFriends();
      });
    });

    // tải tên người dùng
    try {
      final user = await _userRepository.getUserById(_targetUserId!);
      if (mounted && user != null) {
        setState(() {
          _userName = user.displayName ?? 'Người dùng';
        });
      }
    } catch (e) {
      // bỏ qua
    }

    // lắng nghe stream người theo dõi
    _userRepository
        .getFollowers(_targetUserId!)
        .listen(
          (followers) async {
            if (!mounted) return;
            final filtered = followers
                .where(
                  (u) => u.uid != _targetUserId && !_blockedIds.contains(u.uid),
                )
                .toList();
            // cập nhật danh sách; đánh dấu đã tải followers (ẩn spinner tổng khi tất cả stream xong)
            setState(() {
              _followers = filtered;
              _loadingFollowers = false;
              // tính liệu mỗi người theo dõi có cũng theo dõi tôi không
              for (var u in filtered) {
                _userRepository.isFollowingMe(u.uid).then((follows) {
                  if (!mounted) return;
                  setState(() {
                    _followsMe[u.uid] = follows;
                  });
                });
              }
              _computeCommon();
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });

            // bây giờ tính trạng thái theo dõi song song bất đồng bộ
            final futures = followers
                .map((f) => _userRepository.isFollowing(f.uid))
                .toList();
            final results = await Future.wait(futures);
            if (!mounted) return;
            for (int i = 0; i < followers.length; i++) {
              _followStatus[followers[i].uid] = results[i];
            }
            final requestChecks = followers
                .map((f) => _userRepository.isFollowRequested(f.uid))
                .toList();
            final requestResults = await Future.wait(requestChecks);
            if (!mounted) return;
            for (int i = 0; i < followers.length; i++) {
              _requestStatus[followers[i].uid] = requestResults[i];
            }
            setState(() {});
            _calculateFriends();
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _loadError = true;
              _followers = [];
              _loadingFollowers = false;
              _loadingFriends = false;
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });
          },
        );

    // lắng nghe stream đang theo dõi
    _userRepository
        .getFollowing(_targetUserId!)
        .listen(
          (following) async {
            if (!mounted) return;
            final filtered = following
                .where(
                  (u) => u.uid != _targetUserId && !_blockedIds.contains(u.uid),
                )
                .toList();
            setState(() {
              // loại bỏ chính mình khỏi danh sách đang theo dõi
              _following = filtered;
              _loadingFollowing = false;
              _computeCommon();
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });

            // tính trạng thái theo dõi cho từng người giống như trong stream follower
            final futures = following
                .map((f) => _userRepository.isFollowing(f.uid))
                .toList();
            final results = await Future.wait(futures);
            if (!mounted) return;
            for (int i = 0; i < following.length; i++) {
              _followStatus[following[i].uid] = results[i];
            }
            final requestChecks = following
                .map((f) => _userRepository.isFollowRequested(f.uid))
                .toList();
            final requestResults = await Future.wait(requestChecks);
            if (!mounted) return;
            for (int i = 0; i < following.length; i++) {
              _requestStatus[following[i].uid] = requestResults[i];
            }
            setState(() {});
            _calculateFriends();
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _loadError = true;
              _following = [];
              _loadingFollowing = false;
              _loadingFriends = false;
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });
          },
        );

    if (_showRequests && _currentUserId != null) {
      FirebaseUserService()
          .getFollowRequests(_currentUserId!)
          .listen(
            (requests) {
              if (!mounted) return;
              setState(() {
                _followRequests = requests
                    .where((u) => !_blockedIds.contains(u.uid))
                    .toList();
                _loadingRequests = false;
              });
            },
            onError: (_) {
              if (!mounted) return;
              setState(() {
                _followRequests = [];
                _loadingRequests = false;
              });
            },
          );
    }
  }

  void _calculateFriends() {
    // Bạn bè của người dùng mục tiêu = những người theo dõi lẫn nhau
    final followerIds = _followers.map((f) => f.uid).toSet();
    final followingIds = _following.map((f) => f.uid).toSet();
    final friendIds = followerIds.intersection(followingIds);

    _friends = _followers.where((f) => friendIds.contains(f.uid)).toList();
    if (mounted) {
      _loadingFriends = false;
      // once target's friends updated we can recompute mutuals
      _computeCommon();
      setState(() {});
    }
  }

  /// Calculate friends for the current user (used when showing mutual friends)
  void _calculateMyFriends() {
    final followerIds = _myFollowers.map((f) => f.uid).toSet();
    final followingIds = _myFollowing.map((f) => f.uid).toSet();
    final friendIds = followerIds.intersection(followingIds);

    _myFriends = _myFollowers.where((f) => friendIds.contains(f.uid)).toList();
    // recalc mutuals whenever our friends list changes
    _computeCommon();
  }

  /// Load both follower and following lists for the current user so that
  /// we can calculate mutual relationships (following and friends).
  void _loadMyData() {
    if (_currentUserId == null) return;

    // following stream
    _userRepository
        .getFollowing(_currentUserId!)
        .listen(
          (following) async {
            if (!mounted) return;
            final filtered = following
                .where(
                  (u) =>
                      u.uid != _currentUserId && !_blockedIds.contains(u.uid),
                )
                .toList();
            setState(() {
              _myFollowing = filtered;
              _loadingMyFollowing = false;
              _calculateMyFriends();
              // _computeCommon called from _calculateMyFriends
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowers ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _loadError = true;
              _myFollowing = [];
              _loadingMyFollowing = false;
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowers ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });
          },
        );

    // followers stream
    _userRepository
        .getFollowers(_currentUserId!)
        .listen(
          (followers) async {
            if (!mounted) return;
            final filtered = followers
                .where(
                  (u) =>
                      u.uid != _currentUserId && !_blockedIds.contains(u.uid),
                )
                .toList();
            setState(() {
              _myFollowers = filtered;
              _loadingMyFollowers = false;
              _calculateMyFriends();
              // _computeCommon called from _calculateMyFriends
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowers ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _loadError = true;
              _myFollowers = [];
              _loadingMyFollowers = false;
              _isLoading =
                  _loadingFollowers ||
                  _loadingFollowing ||
                  _loadingMyFollowers ||
                  _loadingMyFollowing ||
                  _loadingFriends;
            });
          },
        );
  }

  void _computeCommon() {
    // intersection of myFollowing and target's following by uid
    final myIds = _myFollowing.map((u) => u.uid).toSet();
    _commonFollowing = _following.where((u) => myIds.contains(u.uid)).toList();

    // intersection of myFriends and target's friends
    final myFriendIds = _myFriends.map((u) => u.uid).toSet();
    _commonFriends = _friends
        .where((u) => myFriendIds.contains(u.uid))
        .toList();

    if (mounted) {
      _loadingCommon = false;
      _loadingCommonFriends = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError && !_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _userName.isEmpty ? 'Đang tải...' : _userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        body: const Center(child: Text('Không thể tải danh sách người dùng')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userName.isEmpty ? 'Đang tải...' : _userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable:
              true, // allow horizontal scrolling so tabs aren't clipped
          labelColor: const Color(0xFF113953),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF113953),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: [
            if (_showCommon)
              Tab(text: 'Người theo dõi chung (${_commonFollowing.length})'),
            Tab(text: 'Người theo dõi (${_followers.length})'),
            Tab(text: 'Đang theo dõi (${_following.length})'),
            Tab(text: 'Bạn bè (${_friends.length})'),
            if (_showRequests) Tab(text: 'Yêu cầu (${_followRequests.length})'),
            if (_showCommon) Tab(text: 'Bạn chung (${_commonFriends.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (_showCommon) ...[
            // common followings (people both you and the profile user follow)
            _loadingCommon
                ? const Center(child: CircularProgressIndicator())
                : buildUserList(_commonFollowing, isCommonFollowingTab: true),
          ],
          _loadingFollowers
              ? const Center(child: CircularProgressIndicator())
              : buildUserList(_followers, isFollowerTab: true),
          _loadingFollowing
              ? const Center(child: CircularProgressIndicator())
              : buildUserList(_following, isFollowingTab: true),
          _loadingFriends
              ? const Center(child: CircularProgressIndicator())
              : buildUserList(_friends, isFriendTab: true),
          if (_showRequests)
            _loadingRequests
                ? const Center(child: CircularProgressIndicator())
                : buildUserList(_followRequests, isRequestTab: true),
          if (_showCommon)
            _loadingCommonFriends
                ? const Center(child: CircularProgressIndicator())
                : buildUserList(_commonFriends, isCommonFriendsTab: true),
        ],
      ),
    );
  }

  Widget buildUserList(
    List<UserModel> users, {
    bool isFollowerTab = false,
    bool isFollowingTab = false,
    bool isFriendTab = false,
    bool isCommonFollowingTab = false,
    bool isCommonFriendsTab = false,
    bool isRequestTab = false,
  }) {
    if (users.isEmpty) {
      // choose icon based on tab type; reuse group icon for friend/common tabs
      IconData icon;
      String message;
      if (isFollowerTab) {
        icon = Icons.people_outline;
        message = 'Chưa có người theo dõi';
      } else if (isFollowingTab) {
        icon = Icons.person_add_alt_1_outlined;
        message = 'Bạn chưa theo dõi ai';
      } else if (isRequestTab) {
        icon = Icons.person_add_alt_1_outlined;
        message = 'Chưa có yêu cầu theo dõi';
      } else if (isCommonFollowingTab) {
        icon = Icons.people_outline;
        message = 'Không có người theo dõi chung';
      } else if (isCommonFriendsTab) {
        icon = Icons.group_outlined;
        message = 'Không có bạn chung';
      } else {
        // friend tab default
        icon = Icons.group_outlined;
        message = 'Chưa có bạn bè';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
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
        return buildUserItem(
          user,
          isFollowerTab: isFollowerTab,
          isFollowingTab: isFollowingTab,
          isFriendTab: isFriendTab,
          isRequestTab: isRequestTab,
        );
      },
    );
  }

  Widget buildUserItem(
    UserModel user, {
    bool isFollowerTab = false,
    bool isFollowingTab = false,
    bool isFriendTab = false,
    bool isRequestTab = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Profile(userId: user.uid, showBottomNav: true, initialTab: 0),
          ),
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
                  child: user.photoUrl != null
                      ? Image.network(
                          user.photoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return buildDefaultAvatar();
                          },
                        )
                      : buildDefaultAvatar(),
                ),
                // only show green online dot when viewing own profile's friend list
                if (isFriendTab && _targetUserId == _currentUserId)
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
                    user.displayName ?? 'Người dùng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF113953),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.email.split('@').first}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Nút hành động
            buildActionButton(
              user,
              isFollowerTab,
              isFollowingTab,
              isFriendTab,
              isRequestTab,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDefaultAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Icon(Icons.person, size: 35, color: Colors.grey),
    );
  }

  Widget buildActionButton(
    UserModel user,
    bool isFollowerTab,
    bool isFollowingTab,
    bool isFriendTab,
    bool isRequestTab,
  ) {
    // don't show actions for self
    if (user.uid == _currentUserId) {
      return const SizedBox.shrink();
    }
    final bool isFollowing = _followStatus[user.uid] ?? false;
    final bool followsMe = _followsMe[user.uid] ?? false;
    final bool isRequested = _requestStatus[user.uid] ?? false;
    String buttonText() {
      // mutual follow == friends
      if (isFollowing && followsMe) return 'Bạn bè';
      if (!isFollowing && followsMe) return 'Theo dõi lại';
      if (isRequested) return 'Đã gửi';
      return isFollowing ? 'Đang theo dõi' : 'Theo dõi';
    }

    if (isRequestTab) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () async {
              await _userRepository.declineFollowRequest(user.uid);
              if (!mounted) return;
              setState(() {
                _followRequests.removeWhere((u) => u.uid == user.uid);
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: const StadiumBorder(),
            ),
            child: const Text('Từ chối'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await _userRepository.acceptFollowRequest(user.uid);
              if (!mounted) return;
              setState(() {
                _followRequests.removeWhere((u) => u.uid == user.uid);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB620),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: const StadiumBorder(),
            ),
            child: const Text('Chấp nhận'),
          ),
        ],
      );
    }

    if (isFriendTab) {
      final bool isOwnerView = _targetUserId == _currentUserId;
      if (isOwnerView) {
        // owner sees combined overflow menu (chat + unfriend)
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          onSelected: (value) {
            if (value == 'chat') {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    user: {'id': user.uid, 'name': user.displayName ?? ''},
                  ),
                ),
              );
            } else if (value == 'unfriend') {
              showUnfriendDialog(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'chat',
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Color(0xFF113953)),
                  SizedBox(width: 4),
                  Text('Nhắn tin'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'unfriend',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: Colors.red),
                  SizedBox(width: 4),
                  Text('Hủy kết bạn'),
                ],
              ),
            ),
          ],
        );
      } else {
        // viewing someone else's friends list: show a follow/unfollow button
        // that uses the same `buttonText` logic as other tabs.  this ensures
        // that when the profile owner *and* the current user both follow the
        // listed person the label becomes "Bạn bè".
        return ElevatedButton(
          onPressed: () => toggleFollow(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: (isFollowing && followsMe)
                ? Colors.grey[200]
                : isFollowing
                ? Colors.grey[200]
                : (isRequested ? Colors.grey[300] : const Color(0xFFFFB620)),
            foregroundColor: (isFollowing || isRequested)
                ? Colors.black87
                : Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(buttonText()),
        );
      }
    }

    if (isFollowingTab) {
      // show follow/unfollow according to current user's state
      // if they are already friends we still allow tap to unfollow
      return ElevatedButton(
        onPressed: () => toggleFollow(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: (isFollowing && followsMe)
              ? Colors.grey[200]
              : isFollowing
              ? Colors.grey[200]
              : (isRequested ? Colors.grey[300] : const Color(0xFFFFB620)),
          foregroundColor: (isFollowing || isRequested)
              ? Colors.black87
              : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: const StadiumBorder(),
        ),
        child: Text(buttonText()),
      );
    }

    // Tab người theo dõi (exclude self)
    // only show delete-option when user is looking at their own profile;
    // when viewing someone else's account we can't remove followers for them.
    final bool isOwnerView = _targetUserId == _currentUserId;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            if (!_ensureSignedIn()) return;
            toggleFollow(user);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: (isFollowing && followsMe)
                ? Colors.grey[200]
                : isFollowing
                ? Colors.grey[200]
                : (isRequested ? Colors.grey[300] : const Color(0xFFFFB620)),
            foregroundColor: (isFollowing || isRequested)
                ? Colors.black87
                : Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            shape: const StadiumBorder(),
          ),
          child: Text(buttonText()),
        ),
        // remove-follower menu only when viewing your own profile and not yourself
        if (isOwnerView && user.uid != _currentUserId)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'remove') {
                showRemoveFollowerDialog(user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa người theo dõi'),
                  ],
                ),
              ),
            ],
          ),
        // no separate label now; buttonText handles follow-back state
      ],
    );
  }

  Future<void> toggleFollow(UserModel user) async {
    if (!_ensureSignedIn()) return;
    final isCurrentlyFollowing = _followStatus[user.uid] ?? false;
    final isRequested = _requestStatus[user.uid] ?? false;

    try {
      if (isCurrentlyFollowing) {
        await _userRepository.unfollowUser(user.uid);
      } else if (isRequested) {
        await _userRepository.cancelFollowRequest(user.uid);
        setState(() {
          _requestStatus[user.uid] = false;
        });
        return;
      } else {
        final isPrivate = await FirebaseUserService().isPrivateAccount(
          user.uid,
        );
        if (isPrivate) {
          await _userRepository.requestFollow(user.uid);
          setState(() {
            _requestStatus[user.uid] = true;
          });
          return;
        }
        await _userRepository.followUser(user.uid);
      }

      setState(() {
        _followStatus[user.uid] = !isCurrentlyFollowing;
        if (_followStatus[user.uid] == true) {
          _requestStatus[user.uid] = false;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void showRemoveFollowerDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người theo dõi'),
        content: Text(
          'Bạn có chắc muốn xóa ${user.displayName} khỏi danh sách người theo dõi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userRepository.removeFollower(user.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã xóa ${user.displayName} khỏi danh sách người theo dõi',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showUnfriendDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text(
          'Bạn có chắc muốn hủy kết bạn với ${user.displayName}?\n\nCả hai sẽ không còn theo dõi nhau nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userRepository.unfriendUser(user.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã hủy kết bạn với ${user.displayName}'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
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
