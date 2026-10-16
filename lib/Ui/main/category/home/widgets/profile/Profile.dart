// đây là file chứa code của trang profile chính trong phần home
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/create_and_edit_content.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/thongbao_profile.dart';
import 'package:tourn/Ui/main/main_page.dart';
import 'package:tourn/Ui/main/category/home/widgets/Album_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Followers_and_Are_following.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Newfeed_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/check_in.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/edit_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/intro_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/video_profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/search.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Menuprofile.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/Ui/main/category/home/widgets/story/story_avatar.dart';
import 'package:tourn/Ui/main/widget/custom_bottom_nav_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/goiytheodoi_page.dart';

class Profile extends StatefulWidget {
  /// when non-null, the widget will display the profile for the
  /// specified user id instead of the currently signed‑in user.
  final String? userId;
  final String? name;
  final String? avatar;
  final bool isOnline;
  final bool showBottomNav; // Hiển thị bottom nav khi mở từ chat
  final int initialTab; // tab để đánh dấu khi showBottomNav = true

  const Profile({
    super.key,
    this.userId,
    this.name,
    this.avatar,
    this.isOnline = false,
    this.showBottomNav = false,
    this.initialTab = 0,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int _selectedTab = 0; // Biến để theo dõi tab được chọn
  bool _userLoadError = false;

  // notification prefs for each category (post, story, reels, live)
  // values: 'all', 'best', 'off'
  // default to 'best' for everything as requested
  final Map<String, String> _notifPreference = {
    'post': 'best',
    'story': 'best',
    'reels': 'best',
    'live': 'best',
  };

  // when the notification bell is tapped we record the global position so
  // that if the user opens a submenu and then returns to the main menu we
  // can anchor the reopened menu back at the bell instead of at the last
  // tapped tile (which was the cause of the "menu jumps to a different
  // location" bug).
  Offset? _notifMenuAnchor;

  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker
  String? _avatarPath;
  UserModel? _currentUser;
  bool _isFollowing = false; // whether current user follows this profile
  bool _isFollower = false; // whether this profile follows current user
  bool _isBusinessMode = false; // only for current user profile
  bool _otherBusinessMode = false; // other user's business mode fallback
  bool _isPrivateAccount = false; // whether viewed profile is private
  bool _privacyLoaded = false;
  bool _hasRequestedFollow = false;
  bool _showSuggestions = false;
  bool _suggestionsLoading = false;
  List<UserModel> _suggestions = [];
  final Set<String> _dismissedSuggestionIds = {};
  final Map<String, bool> _suggestFollowOverrides = {};
  final Map<String, bool> _suggestRequestOverrides = {};

  /// true when each account follows the other
  bool get _areFriends => _isFollowing && _isFollower;
  bool _isBlocked = false; // have we blocked this profile?
  List<String> _blockedIds = []; // users blocked by the viewer (current user)
  StreamSubscription<UserModel?>? _userSub;
  StreamSubscription<List<String>>? _blockedSub;
  StreamSubscription<List<UserModel>>?
  _followersSub; // watch follower list for header
  StreamSubscription<List<UserModel>>?
  _followingSub; // watch following list for header

  // explicit id of the profile being displayed (or null for current user)
  String? _profileUserId;

  // number of followers visible to the current viewer (after filtering)
  int _visibleFollowers = 0;
  int _visibleFollowing = 0; // count after filtering self and blocked

  // lists from the repository streams (unfiltered)
  List<UserModel> _followersList = [];
  List<UserModel> _followingList = [];
  // cached ids (still useful for some callbacks)
  List<String> _followerIds = [];
  List<String> _followingIds = [];

  // for computing common friends (bạn chung)
  List<String> _myFollowerIds = [];
  List<String> _myFollowingIds = [];
  List<String> _myRequestedIds = [];
  StreamSubscription<List<UserModel>>? _myFollowersSub;
  StreamSubscription<List<UserModel>>? _myFollowingSub;
  StreamSubscription<UserModel?>? _myUserSub;
  List<UserModel> _commonFriends = []; // cached common friends

  // private nickname the current user set for this profile
  String? _nickname;
  StreamSubscription<String?>? _nicknameSub;

  @override
  void initState() {
    super.initState();
    final repo = context.read<UserRepository>();
    _profileUserId = widget.userId ?? repo.currentUserId;

    if (_profileUserId != null) {
      _loadPrivacySettings(_profileUserId!);
    }

    final currentId = repo.currentUserId;
    if (_profileUserId != null && _profileUserId == currentId) {
      _loadBusinessMode();
    }
    if (_profileUserId != null && _profileUserId != currentId) {
      _loadOtherBusinessMode(_profileUserId!);
      _loadFollowRequestStatus(_profileUserId!);
    }

    // listen to the current user's blocked list so that counts and
    // follower/following tabs can exclude blocked accounts.  also turn the
    // flag on/off when the profile in view appears in that list.
    _blockedSub = FirebaseUserService().blockedIdsStream().listen((ids) {
      if (!mounted) return;
      setState(() {
        _blockedIds = ids;
        if (_profileUserId != null) {
          _isBlocked = ids.contains(_profileUserId);
        }
        // recalc counts from the full lists so header always matches the
        // followers/following tabs (same filter used there).
        _visibleFollowers = _followersList
            .where(
              (u) => u.uid != _profileUserId && !_blockedIds.contains(u.uid),
            )
            .length;
        _visibleFollowing = _followingList
            .where(
              (u) => u.uid != _profileUserId && !_blockedIds.contains(u.uid),
            )
            .length;
      });
    });

    if (_profileUserId != null) {
      _userSub = repo
          .streamUser(_profileUserId!)
          .listen(
            (user) {
              if (!mounted) return;
              setState(() {
                _currentUser = user;
                _userLoadError = false;
                // note: we intentionally do **not** recompute follower/following
                // counts here.  those values are kept in sync by the dedicated
                // follower/following streams above; using the user document leads
                // to races and mismatches as seen previously.
              });
            },
            onError: (error) {
              if (!mounted) return;
              setState(() {
                _currentUser = null;
                _userLoadError = true;
              });
            },
          );
      _loadUser(_profileUserId!);
      _checkBlocked(_profileUserId!);

      final curId = repo.currentUserId;
      if (curId != null && curId != _profileUserId) {
        _myUserSub = repo
            .streamUser(curId)
            .listen(
              (user) {
                if (!mounted) return;
                setState(() {
                  _myRequestedIds = user?.followRequested ?? [];
                });
              },
              onError: (_) {
                if (!mounted) return;
                setState(() {
                  _myRequestedIds = [];
                });
              },
            );
        // subscribe to nickname stream
        _nicknameSub = FirebaseUserService()
            .nicknameStream(_profileUserId!)
            .listen(
              (nick) {
                if (mounted) setState(() => _nickname = nick);
              },
              onError: (_) {
                if (mounted) setState(() => _nickname = null);
              },
            );
        // track who follows me (my followers)
        _myFollowersSub = repo
            .getFollowers(curId)
            .listen(
              (list) {
                if (!mounted) return;
                setState(() {
                  _myFollowerIds = list.map((u) => u.uid).toList();
                  _computeCommon();
                });
              },
              onError: (_) {
                if (!mounted) return;
                setState(() {
                  _myFollowerIds = [];
                });
              },
            );
        // track who I follow (my following)
        _myFollowingSub = repo
            .getFollowing(curId)
            .listen(
              (list) {
                if (!mounted) return;
                setState(() {
                  _myFollowingIds = list.map((u) => u.uid).toList();
                  _computeCommon();
                });
              },
              onError: (_) {
                if (!mounted) return;
                setState(() {
                  _myFollowingIds = [];
                });
              },
            );
      }

      // also subscribe to the follower stream to keep header count in sync
      _followersSub = repo
          .getFollowers(_profileUserId!)
          .listen(
            (followers) {
              if (!mounted) return;
              setState(() {
                // make sure duplicates are removed just in case the repository
                // stream ever emits them.
                final unique = <String, UserModel>{};
                for (var u in followers) {
                  unique[u.uid] = u;
                }
                _followersList = unique.values.toList();
                _followerIds = _followersList.map((u) => u.uid).toList();
                _visibleFollowers = _followersList
                    .where(
                      (u) =>
                          u.uid != _profileUserId &&
                          !_blockedIds.contains(u.uid),
                    )
                    .length;
                _computeCommon();
              });
            },
            onError: (_) {
              if (!mounted) return;
              setState(() {
                _followersList = [];
                _followerIds = [];
                _visibleFollowers = 0;
              });
            },
          );

      // and also watch the following list itself (could diverge from
      // _currentUser.following in rare cases) to drive the header count
      _followingSub = repo
          .getFollowing(_profileUserId!)
          .listen(
            (following) {
              if (!mounted) return;
              setState(() {
                final unique = <String, UserModel>{};
                for (var u in following) {
                  unique[u.uid] = u;
                }
                _followingList = unique.values.toList();
                _followingIds = _followingList.map((u) => u.uid).toList();
                _visibleFollowing = _followingList
                    .where(
                      (u) =>
                          u.uid != _profileUserId &&
                          !_blockedIds.contains(u.uid),
                    )
                    .length;
                _computeCommon();
              });
            },
            onError: (_) {
              if (!mounted) return;
              setState(() {
                _followingList = [];
                _followingIds = [];
                _visibleFollowing = 0;
              });
            },
          );
    }
  }

  Future<void> _loadUser(String uid) async {
    try {
      final userRepository = context.read<UserRepository>();
      final user = await userRepository.getUserById(uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
          final curId = userRepository.currentUserId;
          _isFollowing =
              curId != null && _currentUser?.followers.contains(curId) == true;
          // check if viewed user follows current user via their following list
          if (curId != null) {
            _isFollower = _currentUser?.following.contains(curId) == true;
          }
          if (_currentUser != null) {
            final ownProfile = _profileUserId == curId;
            _isFollowing =
                curId != null &&
                _currentUser?.followers.contains(curId) == true;
            if (curId != null) {
              _isFollower = _currentUser?.following.contains(curId) == true;
            }
            // do not set counts here; those are maintained by the streams
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userLoadError = true;
      });
    }
  }

  Future<void> _loadBusinessMode() async {
    try {
      final settings = await FirebaseAccountService().getAccountSettings();
      if (!mounted) return;
      setState(() {
        _isBusinessMode = settings.isBusinessAccount;
      });
    } catch (e) {
      // Ignore errors for optional label
    }
  }

  Future<void> _loadOtherBusinessMode(String uid) async {
    try {
      final settings = await FirebaseAccountService().getAccountSettingsForUser(
        uid,
      );
      if (!mounted) return;
      setState(() {
        _otherBusinessMode = settings.isBusinessAccount;
      });
    } catch (e) {
      // Ignore errors for optional label
    }
  }

  Future<void> _loadPrivacySettings(String uid) async {
    try {
      final service = FirebaseAccountService();
      final currentId = service.currentUserId;
      final settings = currentId == uid
          ? await service.getAccountSettings()
          : await service.getAccountSettingsForUser(uid);
      var isPrivate = settings.isPrivate;
      if (currentId != uid) {
        final userPrivate = await FirebaseUserService().isPrivateAccount(uid);
        isPrivate = userPrivate;
      }
      if (!mounted) return;
      setState(() {
        _isPrivateAccount = isPrivate;
        _privacyLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _privacyLoaded = true);
    }
  }

  Future<void> _loadFollowRequestStatus(String uid) async {
    try {
      final repo = context.read<UserRepository>();
      final currentId = repo.currentUserId;
      if (currentId == null || currentId == uid) return;
      final requested = await repo.isFollowRequested(uid);
      if (!mounted) return;
      setState(() {
        _hasRequestedFollow = requested;
      });
    } catch (_) {
      // ignore
    }
  }

  bool _canViewPrivateContent(BuildContext context) {
    final repo = context.read<UserRepository>();
    final currentId = repo.currentUserId;
    final viewingOther = widget.userId != null && widget.userId != currentId;
    if (!viewingOther) return true;
    if (!_isPrivateAccount) return true;
    return _isFollowing;
  }

  Widget _buildPrivatePlaceholder() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: const [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tài khoản riêng tư',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Chỉ người theo dõi đã được chấp nhận mới xem được nội dung.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _computeCommon() {
    // My friends = people who follow me AND I follow them
    final myFollowerSet = _myFollowerIds.toSet();
    final myFollowingSet = _myFollowingIds.toSet();
    final myFriendIds = myFollowerSet.intersection(myFollowingSet);

    // Their friends = people who follow them AND they follow back
    final theirFollowerIds = _followersList.map((u) => u.uid).toSet();
    final theirFollowingIds = _followingList.map((u) => u.uid).toSet();
    final theirFriendIds = theirFollowerIds.intersection(theirFollowingIds);

    // Common friends = intersection of my friends and their friends
    final commonFriendIds = myFriendIds.intersection(theirFriendIds);
    _commonFriends = _followersList
        .where((u) => commonFriendIds.contains(u.uid))
        .toList();
  }

  Future<void> _checkBlocked(String uid) async {
    final blocked = await FirebaseUserService().isBlocked(uid);
    if (blocked && mounted) {
      setState(() {
        _isBlocked = true;
      });
      // show feedback; the UI will display placeholder content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã chặn tài khoản này')),
        );
      });
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _blockedSub?.cancel();
    _followersSub?.cancel();
    _followingSub?.cancel();
    _myFollowersSub?.cancel();
    _myFollowingSub?.cancel();
    _myUserSub?.cancel();
    _nicknameSub?.cancel();
    super.dispose();
  }

  // ---- Nickname dialog ----
  void _showNicknameDialog() {
    final controller = TextEditingController(text: _nickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt tên gợi nhớ'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên gợi nhớ'),
          maxLength: 30,
        ),
        actions: [
          if (_nickname != null && _nickname!.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await FirebaseUserService().setNickname(_profileUserId!, '');
                if (mounted) setState(() => _nickname = null);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                await FirebaseUserService().setNickname(_profileUserId!, text);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        print('Profile _pickImage: selected ${picked.path}');
        setState(() => _avatarPath = picked.path);

        // Upload to Firebase
        try {
          final repo = context.read<UserRepository>();
          print('Profile _pickImage: calling updateProfilePhoto');
          final url = await repo.updateProfilePhoto(File(picked.path));
          print('Profile _pickImage: result url=$url');
          if (url != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật ảnh đại diện'),
                backgroundColor: Colors.green,
              ),
            );
            // Clear local path to show network version
            setState(() => _avatarPath = null);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể cập nhật ảnh đại diện'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e, stackTrace) {
          print('Profile _pickImage error: $e');
          print('Profile _pickImage stackTrace: $stackTrace');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải ảnh: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Profile _pickImage outer error: $e');
    }
  }

  void _viewAvatar() {
    // upgraded self-avatar dialog to match other-avatar styling with edit action
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.5 * 255).round()),
      builder: (context) {
        final profileLink =
            'https://example.com/user/${_currentUser?.uid ?? ''}';
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 170,
                      backgroundImage: _avatarPath != null
                          ? FileImage(File(_avatarPath!))
                          : (_currentUser?.photoUrl != null
                                ? getImageProvider(_currentUser!.photoUrl!)
                                : const AssetImage('asset/images/anh-mo-ta.jpg')
                                      as ImageProvider),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionItem(
                      icon: Icons.send,
                      label: 'Chia sẻ',
                      onTap: () => Share.share(profileLink),
                    ),
                    const SizedBox(width: 24),
                    _actionItem(
                      icon: Icons.link,
                      label: 'Liên kết',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profileLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép')),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    _actionItem(
                      icon: Icons.qr_code,
                      label: 'Mã QR',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Mã QR'),
                            content: const SizedBox(
                              height: 150,
                              child: Center(child: Text('QR code placeholder')),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    _actionItem(
                      icon: Icons.edit,
                      label: 'Chỉnh sửa avatar',
                      onTap: () {
                        Navigator.pop(context);
                        _showAvatarEditMenu(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // newer overlay dialog matching screenshot style
  void _viewOtherAvatar2() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.5 * 255).round()),
      builder: (context) {
        final profileLink =
            'https://example.com/user/${_currentUser?.uid ?? ''}';
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 170,
                      backgroundImage: _currentUser?.photoUrl != null
                          ? getImageProvider(_currentUser!.photoUrl!)
                          : const AssetImage('asset/images/OIP.jpg')
                                as ImageProvider,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionItem(
                      icon: _isFollowing
                          ? Icons.person_remove_alt_1
                          : (_hasRequestedFollow
                                ? Icons.hourglass_empty
                                : Icons.person_add_alt_1),
                      label: _hasRequestedFollow
                          ? 'Đã gửi'
                          : (_isFollowing ? 'Bỏ theo dõi' : 'Theo dõi'),
                      onTap: () {
                        Navigator.pop(context);
                        _toggleFollow();
                      },
                    ),
                    const SizedBox(width: 24),
                    _actionItem(
                      icon: Icons.send,
                      label: 'Chia sẻ',
                      onTap: () => Share.share(profileLink),
                    ),
                    const SizedBox(width: 24),
                    _actionItem(
                      icon: Icons.link,
                      label: 'Liên kết',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profileLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép')),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    _actionItem(
                      icon: Icons.qr_code,
                      label: 'Mã QR',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Mã QR'),
                            content: const SizedBox(
                              height: 150,
                              child: Center(child: Text('QR code placeholder')),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // helper that builds one of the black-circled action icons used in
  // the "other avatar" dialog so the row layout stays tidy.
  Widget _actionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    // general bottom sheet used elsewhere (not avatar viewer)
    final hasAvatar = _avatarPath != null || _currentUser?.photoUrl != null;
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.remove_red_eye),
              title: const Text('Xem ảnh đại diện'),
              onTap: () {
                Navigator.pop(c);
                _viewAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xóa ảnh đại diện',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(c);
                  final repo = context.read<UserRepository>();
                  final success = await repo.deleteProfilePhoto();
                  if (success) {
                    setState(() {
                      _avatarPath = null;
                      _currentUser = _currentUser?.copyWith(
                        clearPhotoUrl: true,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa ảnh đại diện'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet for editing or deleting user bio (owner only)
  void _showBioBottomSheet() {
    final ctrl = TextEditingController(text: _currentUser?.bio ?? '');
    final isOwner =
        _currentUser?.uid == (context.read<UserRepository>().currentUserId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(c).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiểu sử',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isOwner) ...[
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Viết tiểu sử của bạn...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_currentUser?.bio ?? '').isNotEmpty
                          ? () async {
                              final repo = context.read<UserRepository>();
                              await repo.updateBio('');
                              if (mounted) Navigator.pop(c);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã xóa tiểu sử'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadUser(_profileUserId!);
                            }
                          : null,
                      child: const Text('Xóa tiểu sử'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newBio = ctrl.text.trim();
                        if (newBio.isNotEmpty) {
                          final repo = context.read<UserRepository>();
                          await repo.updateBio(newBio);
                          if (mounted) Navigator.pop(c);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật tiểu sử'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadUser(_profileUserId!);
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                _currentUser?.bio ?? 'Chưa có tiểu sử',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  void _showBusinessIntroSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.of(c).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài khoản doanh nghiệp',
              style: Theme.of(c).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tài khoản doanh nghiệp mở khóa công cụ chuyên nghiệp để tăng '
              'hiệu suất và kết nối khách hàng.',
            ),
            const SizedBox(height: 16),
            _businessIntroRow(
              icon: Icons.insights_outlined,
              title: 'Thống kê & hiệu suất',
              subtitle: 'Theo dõi lượt xem, tương tác và tăng trưởng.',
            ),
            _businessIntroRow(
              icon: Icons.campaign_outlined,
              title: 'Công cụ quảng bá',
              subtitle: 'Tăng độ tiếp cận và gợi ý nội dung.',
            ),
            _businessIntroRow(
              icon: Icons.contact_phone_outlined,
              title: 'Nút liên hệ',
              subtitle: 'Thêm email, số điện thoại, địa chỉ.',
            ),
            _businessIntroRow(
              icon: Icons.storefront_outlined,
              title: 'Hiển thị danh mục',
              subtitle: 'Chọn lĩnh vực kinh doanh phù hợp.',
            ),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight),
          ],
        ),
      ),
    );
  }

  Widget _businessIntroRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF113953).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF113953)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarEditMenu(BuildContext context) {
    // centered modal matching previous screenshot (no Facebook option)
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (c) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuRow(Icons.photo_library, 'Chọn từ thư viện', () {
                Navigator.pop(c);
                _pickImage(ImageSource.gallery);
              }),
              const SizedBox(height: 12),
              _menuRow(Icons.camera_alt, 'Chụp ảnh', () {
                Navigator.pop(c);
                _pickImage(ImageSource.camera);
              }),
              const SizedBox(height: 12),
              _menuRow(Icons.delete_outline, 'Xóa', () {
                Navigator.pop(c);
                setState(() => _avatarPath = null);
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuRow(
    IconData icon,
    String text,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.red : Colors.white),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) {
      // show simple placeholder identical to the screenshot example
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.person, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nội dung này không hiển thị',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: widget.showBottomNav,
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            final username = _currentUser?.username ?? _currentUser?.uid ?? '';
            if (username.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: username));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép: $username'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Text(
            _currentUser?.username ?? _currentUser?.uid ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        actions: [
          // determine whether we're looking at another user's profile
          Builder(
            builder: (context) {
              final repo = context.read<UserRepository>();
              final currentId = repo.currentUserId;
              final viewingOther =
                  widget.userId != null && widget.userId != currentId;
              return Row(
                children: [
                  // first button: either edit (own profile), notifications (other user when followed), or nothing
                  Builder(
                    builder: (ctx) {
                      final showNotifButton = viewingOther && _isFollowing;
                      if (showNotifButton) {
                        // manually open menu on tap; we need tap position
                        return GestureDetector(
                          onTapDown: (details) {
                            _openMainNotificationsMenu(
                              context,
                              details.globalPosition,
                            );
                          },
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.black,
                            size: 20,
                          ),
                        );
                      }
                      if (!viewingOther) {
                        return TextButton(
                          onPressed: () {
                            _gotoeditpage(context);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 20,
                          ),
                        );
                      }
                      // viewing other but not following → empty space
                      return const SizedBox(width: 48);
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      if (viewingOther) {
                        Menuprofile(
                          context,
                          userName: _currentUser?.displayName,
                          userId: _currentUser?.uid,
                        );
                      } else {
                        _gotosearchpage(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Icon(
                      viewingOther ? Icons.more_horiz : Icons.search,
                      color: Colors.black,
                      size: viewingOther ? 24 : 25,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildbodypagescreen(context),
      // Hiển thị bottom navigation bar khi mở từ chat
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: widget.initialTab,
              onItemTapped: (index) {
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => Mainpage(initialTab: index),
                  ),
                );
              },
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined, color: Colors.grey),
                  activeIcon: const Icon(Icons.home, color: Colors.black),
                  label: 'home'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.mail_outline, color: Colors.grey),
                  activeIcon: const Icon(Icons.mail, color: Colors.black),
                  label: 'mail'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map_outlined, color: Colors.grey),
                  activeIcon: const Icon(Icons.map, color: Colors.black),
                  label: 'map'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.favorite_border, color: Colors.grey),
                  activeIcon: const Icon(Icons.favorite, color: Colors.black),
                  label: 'favorite'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline, color: Colors.grey),
                  activeIcon: const Icon(Icons.person, color: Colors.black),
                  label: 'menu'.tr(),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildbodypagescreen(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildcategoryNamefield(),
                  _buildcategorychooseIconfield(context),
                ],
              ),
            ),
          ),
        ];
      },
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildnewfeedprofile(),
      ),
    );
  }

  Widget _buildcategoryNamefield() {
    if (_userLoadError) {
      return SizedBox(
        height: 180,
        child: const Center(child: Text('Không thể tải hồ sơ người dùng')),
      );
    }
    if (_currentUser == null) {
      return SizedBox(
        height: 180,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (ctx) {
                final repo = ctx.read<UserRepository>();
                final currentId = repo.currentUserId;
                final viewingOther =
                    widget.userId != null && widget.userId != currentId;
                Widget avatar = CircleAvatar(
                  radius: 40,
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!))
                      : (_currentUser?.photoUrl != null
                            ? getImageProvider(_currentUser!.photoUrl!)
                            : const AssetImage('asset/images/OIP.jpg')
                                  as ImageProvider),
                );
                if (viewingOther) {
                  // Use StoryAvatar to show story ring when user has active stories
                  return StoryAvatar(
                    userId: widget.userId,
                    photoUrl: _currentUser?.photoUrl,
                    userName: _currentUser?.displayName,
                    radius: 40,
                    onTap: _viewOtherAvatar2,
                  );
                } else {
                  return GestureDetector(
                    onTap: () => _showImageOptions(context),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        avatar,
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    (0.12 * 255).round(),
                                  ),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            // Các cột số liệu chiếm không gian còn lại và co dãn tránh tràn
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("0", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "Điểm đến",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  // Xử lý khi nhấn vào số liệu Người theo dõi
                  final viewingOther =
                      widget.userId != null &&
                      widget.userId !=
                          context.read<UserRepository>().currentUserId;
                  final locked =
                      viewingOther && _isPrivateAccount && !_isFollowing;
                  if (locked) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersAndAreFollowing(
                        initialTabIndex: viewingOther ? 1 : 0,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "$_visibleFollowers",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Người theo dõi",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  // Xử lý khi nhấn vào số liệu Đang theo dõi
                  final viewingOther =
                      widget.userId != null &&
                      widget.userId !=
                          context.read<UserRepository>().currentUserId;
                  final locked =
                      viewingOther && _isPrivateAccount && !_isFollowing;
                  if (locked) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersAndAreFollowing(
                        initialTabIndex: viewingOther ? 2 : 1,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "$_visibleFollowing",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Đang theo dõi",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Name row with optional nickname + pen icon for friends
        Builder(
          builder: (ctx) {
            final repo = ctx.read<UserRepository>();
            final currentId = repo.currentUserId;
            final viewingOther =
                widget.userId != null && widget.userId != currentId;
            final showPen = viewingOther && _areFriends;
            final name = _currentUser?.displayName ?? 'Người dùng';
            final isBusiness = viewingOther
                ? (_otherBusinessMode ||
                      (_currentUser?.isBusinessAccount ?? false))
                : (_currentUser?.isBusinessAccount ?? _isBusinessMode);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: name,
                              style: const TextStyle(
                                color: Color(0xFF113953),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_nickname != null && _nickname!.isNotEmpty)
                              TextSpan(
                                text: ' ($_nickname)',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (showPen) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showNicknameDialog(),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isBusiness)
                  GestureDetector(
                    onTap: _showBusinessIntroSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business_center,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Tài khoản doanh nghiệp',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_currentUser?.bio?.isNotEmpty == true) ...[
          GestureDetector(
            onTap: _showBioBottomSheet,
            child: Text(
              _currentUser!.bio!,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
        // show common-following avatars when looking at another profile
        Builder(
          builder: (ctx) {
            final repo = ctx.read<UserRepository>();
            final currentId = repo.currentUserId;
            final viewingOther =
                widget.userId != null && widget.userId != currentId;
            // use pre-computed common friends (mutual friends)
            final common = _commonFriends;
            if (!viewingOther || common.isEmpty) return const SizedBox.shrink();
            // build row of up to three avatars plus label
            final displayUsers = common.take(3).toList();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersAndAreFollowing(
                        userId: _profileUserId,
                        initialTabIndex: 4, // navigate to mutual friends tab
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Stacked avatars
                    SizedBox(
                      width: 24.0 + (displayUsers.length - 1) * 16.0,
                      height: 24,
                      child: Stack(
                        children: List.generate(displayUsers.length, (index) {
                          final user = displayUsers[index];
                          return Positioned(
                            left: index * 16.0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    user.photoUrl != null &&
                                        user.photoUrl!.isNotEmpty
                                    ? Image.network(
                                        user.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.person,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bạn chung (${common.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF113953),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // when viewing someone else, show follow/message row
        Builder(
          builder: (ctx) {
            final repo = ctx.read<UserRepository>();
            final currentId = repo.currentUserId;
            final viewingOther =
                widget.userId != null && widget.userId != currentId;
            if (!viewingOther) return const SizedBox.shrink();
            // nếu có bio thì thêm khoảng cách trên để tránh dính vào nút, nếu không thì bỏ khoảng cách đó đi cho gọn
            final topPad = (_currentUser?.bio?.isNotEmpty == true) ? 5.0 : 0.0;
            return Padding(
              padding: EdgeInsets.only(top: topPad, bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Colors.grey[300]
                            : (_hasRequestedFollow
                                  ? Colors.grey[300]
                                  : const Color(0xFFFFB620)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size.fromHeight(30),
                      ),
                      child: Text(
                        _hasRequestedFollow
                            ? 'Đã gửi yêu cầu'
                            : (_areFriends
                                  ? 'Bạn bè'
                                  : (_isFollowing
                                        ? 'Đang theo dõi'
                                        : (_isFollower
                                              ? 'Theo dõi lại'
                                              : 'Theo dõi'))),
                        style: TextStyle(
                          color: (_isFollowing || _hasRequestedFollow)
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  if (!(_isPrivateAccount && !_isFollowing))
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _hasRequestedFollow ? null : _messageUser,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size.fromHeight(30),
                        ),
                        child: const Text('Nhắn tin'),
                      ),
                    ),
                  // suggestion icon only visible after following (friends not required)
                  if (_isFollowing) ...[
                    const SizedBox(width: 5),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: _showSuggestions ? Colors.black : Colors.white,
                        border: _showSuggestions
                            ? null
                            : Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _suggestFriend,
                        icon: const Icon(Icons.person_add_alt_1, size: 20),
                        tooltip: 'Đề xuất bạn bè',
                        color: _showSuggestions ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        if (_showSuggestions) _buildSuggestionsSection(),
      ],
    );
  }

  Widget _buildcategorychooseIconfield(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 0);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Trang chủ',
                        style: TextStyle(
                          color: _selectedTab == 0
                              ? const Color(0xFFFFB620)
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 1);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Giới thiệu',
                        style: TextStyle(
                          color: _selectedTab == 1
                              ? Colors.orange
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 2);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Album',
                        style: TextStyle(
                          color: _selectedTab == 2
                              ? Colors.orange
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTab = 3);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: _selectedTab == 3
                              ? Colors.orange
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              // Viết bài
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const createandeditcontent(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit, size: 20, color: Colors.grey),
                      SizedBox(width: 6),
                      Text('Viết bài', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              // Vạch ngăn giữa
              Container(width: 1, height: 45, color: Colors.grey.shade300),

              // Check-in
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckIn()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 6),
                      Text('Check-in', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildnewfeedprofile() {
    if (!_privacyLoaded && widget.userId != null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_canViewPrivateContent(context)) {
      return _buildPrivatePlaceholder();
    }
    switch (_selectedTab) {
      case 0:
        return Newfeedprofile(userId: widget.userId);
      case 1:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Introprofile(userId: widget.userId),
        );
      case 2:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: const AlbumProfile(),
        );
      case 3:
        return VideoProfile(userId: widget.userId);
      default:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: const Text('Tùy chọn chưa có nội dung'),
          ),
        );
    }
  }

  void _gotoeditpage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
  }

  void _gotosearchpage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
  }

  void _toggleFollow() async {
    final repo = context.read<UserRepository>();
    final curId = repo.currentUserId;
    final targetId = widget.userId ?? _currentUser?.uid;
    if (curId == null) {
      _showLoginRequired();
      return;
    }
    if (targetId == null) return;

    try {
      if (_isFollowing) {
        await repo.unfollowUser(targetId);
      } else if (_isPrivateAccount) {
        if (_hasRequestedFollow) {
          await repo.cancelFollowRequest(targetId);
        } else {
          await repo.requestFollow(targetId);
        }
        setState(() {
          _hasRequestedFollow = !_hasRequestedFollow;
        });
        return;
      } else {
        await repo.followUser(targetId);
      }
      setState(() {
        _isFollowing = !_isFollowing;
        // update the in-memory follower list so UI updates immediately; guard
        // against duplicates or stale entries.  the backend streams will
        // correct the list shortly after, so this is only for optimistic UI.
        if (_isFollowing) {
          if (!_currentUser!.followers.contains(curId)) {
            _currentUser!.followers.add(curId);
          }
        } else {
          _currentUser!.followers.removeWhere((id) => id == curId);
        }
        // and recalc visible followers (blockedIds may not have changed)
        if (_currentUser != null) {
          final curId = repo.currentUserId;
          final ownProfile = _profileUserId == curId;
          // use a Set to ignore any duplicate ids that might have sneaked
          // in (either via our optimistic update or upstream).  this mirrors
          // the filtering logic used in the streams higher up.
          _visibleFollowers = _currentUser!.followers.toSet().where((id) {
            if (ownProfile && id == curId) return false;
            if (_blockedIds.contains(id)) return false;
            return true;
          }).length;
        }
      });
    } catch (e) {
      // ignore errors; could show snackbar if desired
    }
  }

  void _messageUser() async {
    final repo = context.read<MessageRepository>();
    final curId = repo.currentUserId;
    final targetId = widget.userId ?? _currentUser?.uid;

    if (curId == null || targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Người dùng chưa đăng nhập hoặc không xác định đối tượng',
          ),
        ),
      );
      return;
    }

    // debug
    debugPrint('messageUser curId=$curId targetId=$targetId');

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      // Get current user's photoUrl from Firestore (base64)
      final userRepo = context.read<UserRepository>();
      final currentUserData = await userRepo.getCurrentUser();
      final conv = await repo.getOrCreatePrivateConversation(
        otherUserId: targetId,
        otherUserName: _currentUser?.displayName ?? '',
        otherUserPhoto: _currentUser?.photoUrl,
        currentUserName: authUser?.displayName,
        currentUserPhoto: currentUserData?.photoUrl,
      );
      if (conv != null && mounted) {
        debugPrint('opening conversation ${conv.id}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FirebaseChatPage(
              conversationId: conv.id,
              displayName: _currentUser?.displayName ?? '',
              displayPhoto: _currentUser?.photoUrl,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tạo được hội thoại')),
        );
      }
    } catch (e) {
      debugPrint('messageUser error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi mở chat: $e')));
    }
  }

  /// Builds the main list tile inside the first popup menu.  When tapped it
  /// will open a secondary menu anchored at the tap location showing the
  /// three choices (All / Best / Off) similar to the screenshots shared by
  /// the user.  We need the [type] string to know which preference map entry
  /// to update.
  /// Helper used for the main notification menu entries.  Instead of
  /// taking a fixed subtitle we display the current preference for the
  /// category (All/Best/Off) beneath the title.  Tapping the tile opens the
  /// submenu that lets the user change that preference.
  Widget _buildMainMenuTile(
    BuildContext context, {
    required IconData icon,
    String? title,
    String? type,
  }) {
    // compact custom tile with fixed height
    String? prefLabel;
    if (type != null) {
      final val = _notifPreference[type];
      if (val == 'all') {
        prefLabel = 'Tất cả';
      } else if (val == 'best')
        prefLabel = 'Phù hợp nhất';
      else if (val == 'off')
        prefLabel = 'Tắt';
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        if (type != null) {
          Navigator.pop(context);
          Future.microtask(
            () =>
                _showNotificationOptions(context, details.globalPosition, type),
          );
        }
      },
      child: Container(
        // make the tile tall enough for two lines of text and icons so we
        // don't get the "BOTTOM OVERFLOWED" errors shown in the screenshot.
        // previously the height was hard‑coded to 24 which is too short for
        // the 14/12 font sizes we use below.
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ensure icons use a consistent size so rows line up nicely
            Icon(icon, size: 24),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title ?? '', style: const TextStyle(fontSize: 14)),
                  if (prefLabel != null)
                    Text(
                      prefLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildPrefIndicator(String? type) {
    if (type == null) return null;
    final val = _notifPreference[type];
    IconData? icon;
    if (val == 'best') {
      icon = Icons.check_circle;
    } else if (val == 'off') {
      icon = Icons.block;
    } // 'all' shows nothing
    return icon != null ? Icon(icon, size: 18, color: Colors.grey) : null;
  }

  /// display the primary notification menu (category list) at the given
  /// screen position.
  Future<void> _openMainNotificationsMenu(
    BuildContext context,
    Offset position,
  ) async {
    // remember where the bell was tapped; we'll reuse this when the
    // submenu closes so the main menu doesn't jump to the last tile
    // position.  we only care about the vertical coordinate since the
    // menu should always be horizontally centered.
    _notifMenuAnchor = position;

    // compute a horizontal center point for the menu.  using the same
    // value for left/right will make showMenu display column-centered.
    final screenW = MediaQuery.of(context).size.width;
    final centerX = screenW / 2;

    await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        centerX,
        position.dy,
        centerX,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          height: 40,
          child: Text(
            'Thông báo từ ${_currentUser?.displayName ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'post',
          height: 40,
          child: _buildMainMenuTile(
            context,
            icon: Icons.image,
            title: 'Bài viết',
            type: 'post',
          ),
        ),
        PopupMenuItem<String>(
          value: 'story',
          height: 40,
          child: _buildMainMenuTile(
            context,
            icon: Icons.brightness_1,
            title: 'Tin',
            type: 'story',
          ),
        ),
        PopupMenuItem<String>(
          value: 'reels',
          height: 40,
          child: _buildMainMenuTile(
            context,
            icon: Icons.video_library,
            title: 'Reels',
            type: 'reels',
          ),
        ),
        PopupMenuItem<String>(
          value: 'live',
          height: 40,
          child: _buildMainMenuTile(
            context,
            icon: Icons.wifi_tethering,
            title: 'Video trực tiếp',
            type: 'live',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'all',
          height: 40,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ),
            leading: const Icon(Icons.person_search),
            title: const Text(
              'Tất cả tài khoản bạn theo dõi',
              style: TextStyle(fontSize: 14),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThongbaoProfile(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showNotificationOptions(
    BuildContext context,
    Offset tapPosition,
    String type,
  ) async {
    // Like the main menu we want the submenu to appear centered
    // horizontally rather than hugging whatever tile the user tapped.
    // compute a horizontal center point and reuse the vertical position
    // passed in so it still opens just below the tapped row.
    final screenW = MediaQuery.of(context).size.width;
    final centerX = screenW / 2;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        centerX,
        tapPosition.dy,
        centerX,
        tapPosition.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          height: 28,
          child: Text(
            // convert type to human-readable
            type == 'post'
                ? 'Bài viết'
                : type == 'story'
                ? 'Tin'
                : type == 'reels'
                ? 'Reels'
                : 'Video trực tiếp',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'all',
          // give a bit more vertical room in the submenu too; 40 matches the
          // main menu style and prevents overflow when the Vietnamese labels
          // wrap or are taller than expected.
          height: 40,
          child: const Text('Tất cả', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem<String>(
          value: 'best',
          height: 40,
          child: const Text('Phù hợp nhất', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem<String>(
          value: 'off',
          height: 40,
          child: const Text('Tắt', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
    if (selected != null) {
      setState(() {
        _notifPreference[type] = selected;
      });
      // reopen the main menu at the same anchor we originally opened it from
      // (the bell icon).  We record that in [_notifMenuAnchor] when the
      // bell is tapped; fall back to the passed tapPosition if something
      // went wrong.
      await _openMainNotificationsMenu(
        context,
        // preserve vertical anchor but horizontal position will be
        // recalculated inside the method to stay centered
        _notifMenuAnchor ?? tapPosition,
      );
    }
  }

  Future<void> _suggestFriend() async {
    final repo = context.read<UserRepository>();
    final currentId = repo.currentUserId;
    if (currentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần đăng nhập để thực hiện thao tác này'),
        ),
      );
      return;
    }

    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
      _suggestionsLoading = true;
    });

    List<UserModel> suggestions = _buildSuggestionCandidates(currentId);
    if (suggestions.isEmpty) {
      suggestions = await _loadStrangerSuggestions(currentId);
    }

    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _suggestionsLoading = false;
    });
  }

  Widget _buildSuggestionsSection() {
    final repo = context.read<UserRepository>();
    final currentId = repo.currentUserId ?? '';
    final requestedIds = _myRequestedIds.toSet();
    final visibleSuggestions = _suggestions
        .where((u) => !_dismissedSuggestionIds.contains(u.uid))
        .where((u) {
          final isFollowing =
              _suggestFollowOverrides[u.uid] ?? u.followers.contains(currentId);
          final isRequested =
              _suggestRequestOverrides[u.uid] ?? requestedIds.contains(u.uid);
          return !isFollowing && !isRequested;
        })
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gợi ý cho bạn',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: visibleSuggestions.isEmpty
                    ? null
                    : () => _openAllSuggestionsPage(visibleSuggestions),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      color: visibleSuggestions.isEmpty
                          ? Colors.grey
                          : const Color(0xFF5C6B7A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_suggestionsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visibleSuggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('Chưa có gợi ý phù hợp')),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final user = visibleSuggestions[index];
                  final isFollowing =
                      _suggestFollowOverrides[user.uid] ??
                      user.followers.contains(currentId);
                  final isRequested =
                      _suggestRequestOverrides[user.uid] ??
                      requestedIds.contains(user.uid);
                  final mutualCount = _mutualFriendCount(currentId, user);

                  return _buildSuggestionCard(
                    user: user,
                    isFollowing: isFollowing,
                    isRequested: isRequested,
                    mutualCount: mutualCount,
                    onFollow: () async {
                      final isPrivate = await FirebaseUserService()
                          .isPrivateAccount(user.uid);
                      if (isPrivate) {
                        await repo.requestFollow(user.uid);
                        if (!mounted) return;
                        setState(() {
                          _suggestRequestOverrides[user.uid] = true;
                          if (!_myRequestedIds.contains(user.uid)) {
                            _myRequestedIds.add(user.uid);
                          }
                        });
                        return;
                      }
                      await repo.followUser(user.uid);
                      if (!mounted) return;
                      setState(() {
                        _suggestFollowOverrides[user.uid] = true;
                        _myRequestedIds.remove(user.uid);
                      });
                    },
                    onUnfollow: () async {
                      if (_suggestRequestOverrides[user.uid] ?? false) {
                        // Hủy yêu cầu follow
                        await repo.cancelFollowRequest(user.uid);
                        if (!mounted) return;
                        setState(() {
                          _suggestRequestOverrides[user.uid] = false;
                          _myRequestedIds.remove(user.uid);
                        });
                      } else {
                        // Unfollow
                        await repo.unfollowUser(user.uid);
                        if (!mounted) return;
                        setState(() {
                          _suggestFollowOverrides[user.uid] = false;
                        });
                      }
                    },
                    onDismiss: () {
                      setState(() {
                        _dismissedSuggestionIds.add(user.uid);
                      });
                    },
                    onOpenProfile: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => Profile(
                            userId: user.uid,
                            showBottomNav: true,
                            initialTab: 0,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required UserModel user,
    required bool isFollowing,
    required bool isRequested,
    required int mutualCount,
    required VoidCallback onFollow,
    required VoidCallback onUnfollow,
    required VoidCallback onDismiss,
    required VoidCallback onOpenProfile,
  }) {
    final username = user.email.split('@').first;
    final avatarProvider = getImageProvider(user.photoUrl);
    return SizedBox(
      width: 150,
      height: 165,
      child: InkWell(
        onTap: onOpenProfile,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(Icons.close, size: 14),
                ),
              ),
              const SizedBox(height: 1),
              ClipOval(
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: avatarProvider != null
                      ? Image(
                          image: avatarProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF113953),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                mutualCount > 0 ? 'Bạn chung $mutualCount' : '@$username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 3),
              Center(
                child: SizedBox(
                  width: 105,
                  height: 26,
                  child: ElevatedButton(
                    onPressed: isFollowing
                        ? onUnfollow
                        : (isRequested ? onUnfollow : onFollow),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.grey.shade300
                          : (isRequested
                                ? Colors.grey.shade300
                                : const Color(0xFFFFB620)),
                      foregroundColor: isFollowing
                          ? Colors.black87
                          : (isRequested ? Colors.black87 : Colors.white),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      isRequested
                          ? 'Đã yêu cầu'
                          : (isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAllSuggestionsPage(List<UserModel> suggestions) {
    final repo = context.read<UserRepository>();
    final currentId = repo.currentUserId ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SuggestionsPage(
          suggestions: suggestions,
          isFollowing: (user) =>
              _suggestFollowOverrides[user.uid] ??
              user.followers.contains(currentId),
          isRequested: (user) =>
              _suggestRequestOverrides[user.uid] ??
              _myRequestedIds.contains(user.uid),
          mutualCount: (user) => _mutualFriendCount(currentId, user),
          onFollow: (user) async {
            final isPrivate = await FirebaseUserService().isPrivateAccount(
              user.uid,
            );
            if (isPrivate) {
              await repo.requestFollow(user.uid);
              if (!mounted) return;
              setState(() {
                _suggestRequestOverrides[user.uid] = true;
                if (!_myRequestedIds.contains(user.uid)) {
                  _myRequestedIds.add(user.uid);
                }
              });
              return;
            }
            await repo.followUser(user.uid);
            if (!mounted) return;
            setState(() {
              _suggestFollowOverrides[user.uid] = true;
              _myRequestedIds.remove(user.uid);
            });
          },
          onUnfollow: (user) async {
            final wasRequested =
                _suggestRequestOverrides[user.uid] ??
                _myRequestedIds.contains(user.uid);
            if (wasRequested) {
              await repo.cancelFollowRequest(user.uid);
              if (!mounted) return;
              setState(() {
                _suggestRequestOverrides[user.uid] = false;
                _myRequestedIds.remove(user.uid);
              });
              return;
            }
            await repo.unfollowUser(user.uid);
            if (!mounted) return;
            setState(() {
              _suggestFollowOverrides[user.uid] = false;
            });
          },
          onDismiss: (user) {
            setState(() {
              _dismissedSuggestionIds.add(user.uid);
            });
          },
        ),
      ),
    );
  }

  List<UserModel> _buildSuggestionCandidates(String currentId) {
    final excluded = <String>{
      currentId,
      if (_profileUserId != null) _profileUserId!,
      ..._blockedIds,
    };

    final pool = <String, UserModel>{};
    for (final u in _followersList) {
      pool[u.uid] = u;
    }
    for (final u in _followingList) {
      pool[u.uid] = u;
    }

    final candidates = pool.values.where((u) {
      if (excluded.contains(u.uid)) return false;
      // hide users already followed
      if (u.followers.contains(currentId)) return false;
      return true;
    }).toList();

    candidates.sort((a, b) {
      final mutualA = _mutualFriendCount(currentId, a);
      final mutualB = _mutualFriendCount(currentId, b);
      if (mutualA != mutualB) return mutualB.compareTo(mutualA);
      return a.displayName.compareTo(b.displayName);
    });

    return candidates;
  }

  Future<List<UserModel>> _loadStrangerSuggestions(String currentId) async {
    final repo = context.read<UserRepository>();
    final excluded = <String>{
      currentId,
      if (_profileUserId != null) _profileUserId!,
      ..._blockedIds,
    };

    final candidates = await repo.searchUsers('');
    final filtered = candidates.where((u) {
      if (excluded.contains(u.uid)) return false;
      if (u.followers.contains(currentId)) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
    return filtered.take(30).toList();
  }

  int _mutualFriendCount(String currentId, UserModel other) {
    final myFriendIds = _myFollowerIds.toSet().intersection(
      _myFollowingIds.toSet(),
    );
    final theirFriendIds = other.followers.toSet().intersection(
      other.following.toSet(),
    );
    return myFriendIds.intersection(theirFriendIds).length;
  }
}
