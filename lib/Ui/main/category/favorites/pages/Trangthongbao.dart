import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/domain/notification_repository/notification_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/notification_model.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/taochuyendi_page.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Datphongkhachsan/Datphongkhachsan_history.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Thuehuongdanvien_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Thuequanaophukien_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Thuethochupanh_Page.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/edit_profile.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.isActive});

  final bool isActive;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final NotificationRepository _repo;
  late final StreamSubscription<User?> _authSub;
  Stream<List<NotificationModel>>? _notificationsStream;

  /// Whether current user has a business account.
  bool _isBusinessAccount = false;
  bool _bizNotificationsEnabled = true;
  StreamSubscription? _userSub;

  /// Tab controller for personal / business tabs (only used in business mode).
  TabController? _tabController;

  List<NotificationModel>? _latestItems;
  bool _initialMarkDone = false;

  void _markCurrentTabAsRead() {
    if (_latestItems == null || !widget.isActive) return;
    
    final isBusinessTab = _isBusinessAccount && _tabController?.index == 1;
    if (isBusinessTab && !_bizNotificationsEnabled) return;

    for (final n in _latestItems!) {
      final isBiz = _isBizNotification(n);
      if (isBusinessTab != isBiz) continue;
      if (!n.isRead) {
        _repo.markAsRead(n.id);
      }
    }
  }

  void _updateStream() {
    _notificationsStream = _repo.getNotifications();
  }

  @override
  void initState() {
    super.initState();
    _repo = context.read<NotificationRepository>();
    _updateStream();

    // Listen for user model changes to detect business mode.
    final userRepo = context.read<UserRepository>();
    _userSub = userRepo.streamCurrentUser().listen((user) {
      final isBiz = user?.isBusinessAccount ?? false;
      if (isBiz != _isBusinessAccount) {
        setState(() {
          _isBusinessAccount = isBiz;
          if (isBiz) {
            _tabController?.dispose();
            _tabController = TabController(length: 2, vsync: this);
            _tabController!.addListener(() {
              if (!_tabController!.indexIsChanging && widget.isActive) {
                _markCurrentTabAsRead();
              }
            });
          } else {
            _tabController?.dispose();
            _tabController = null;
          }
        });
      }
    });

    _loadBusinessNotificationSetting();

    // rebuild whenever authentication state changes so the notification
    // stream can be recreated with the correct uid. this also forces the
    // StreamBuilder to listen to a fresh stream object, avoiding stale
    // subscriptions when switching accounts.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      setState(() {
        _updateStream();
      });
      _loadBusinessNotificationSetting();
    });
  }

  Future<void> _loadBusinessNotificationSetting() async {
    final profile = await FirebaseAccountService().getExtendedProfile() ?? {};
    final businessProfile =
        (profile['businessProfile'] as Map<String, dynamic>?) ?? {};
    final notifications =
        (businessProfile['notifications'] as Map<String, dynamic>?) ?? {};
    final orderEnabled = notifications['order'] ?? true;
    final promoEnabled = notifications['promo'] ?? true;
    if (!mounted) return;
    setState(() {
      _bizNotificationsEnabled = orderEnabled || promoEnabled;
    });
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _markCurrentTabAsRead();
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    _userSub?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  /// Navigate to appropriate booking history page based on booking type
  void _navigateToBookingPage(String? bookingType) {
    Widget page;
    switch (bookingType) {
      case 'hotel':
        page = const HotelBookingHistoryPage();
        break;
      case 'guide':
        page = const ThuehuongdanvienPage();
        break;
      case 'clothes':
        page = const ThuequanaophukienPage();
        break;
      case 'photographer':
        page = const ThuethochupanhPage();
        break;
      default:
        // Fallback to hotel booking history if type is unknown
        page = const HotelBookingHistoryPage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Determine if a notification is business-related.
  /// A notification is considered business-related if:
  /// - It has the `isBusinessNotification` flag set to true, OR
  /// - Its type is `businessAccount`, OR
  /// - It has a bookingId or bookingType (booking-related)
  bool _isBizNotification(NotificationModel item) {
    if (item.isBusinessNotification) return true;
    if (item.type == NotificationType.businessAccount) return true;
    if (item.bookingId != null || item.bookingType != null) return true;
    return false;
  }

  Widget _buildItem(NotificationModel item) {
    IconData icon;
    Color iconColor;

    // Helper function for relative time
    String formatRelativeTime(DateTime dateTime) {
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) {
        return 'Vừa xong';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} phút trước';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} giờ trước';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return '$weeks tuần trước';
      } else {
        // Show actual date
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }

    switch (item.type) {
      case NotificationType.like:
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case NotificationType.comment:
        icon = Icons.comment;
        iconColor = const Color.fromARGB(255, 94, 255, 40);
        break;
      case NotificationType.mention:
        icon = Icons.alternate_email;
        iconColor = Colors.blue;
        break;
      case NotificationType.share:
        icon = Icons.share;
        iconColor = Colors.orange;
        break;
      case NotificationType.live:
        icon = Icons.live_tv;
        iconColor = Colors.red;
        break;
      case NotificationType.follow:
        icon = Icons.person_add;
        iconColor = Colors.purple;
        break;
      case NotificationType.followRequest:
        icon = Icons.person_add_alt_1;
        iconColor = Colors.orange;
        break;
      case NotificationType.message:
        icon = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      case NotificationType.welcome:
        icon = Icons.celebration;
        iconColor = Colors.orange;
        break;
      case NotificationType.completeProfile:
        icon = Icons.edit_note;
        iconColor = const Color(0xFF113953);
        break;
      case NotificationType.businessAccount:
        icon = Icons.storefront;
        iconColor = const Color(0xFF4A7A3C);
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () async {
          await _repo.markAsRead(item.id);

          // Welcome notifications - just mark as read, no navigation
          if (item.type == NotificationType.welcome) {
            return;
          }

          if (item.type == NotificationType.completeProfile) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
            return;
          }

          if (item.type == NotificationType.businessAccount) {
            final uid = _repo.currentUserId;
            if (uid == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    Profile(userId: uid, showBottomNav: true, initialTab: 3),
              ),
            );
            return;
          }

          // Handle message notifications
          if (item.type == NotificationType.message &&
              item.conversationId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FirebaseChatPage(
                  conversationId: item.conversationId!,
                  displayName: item.senderName,
                  displayPhoto: item.senderPhotoUrl,
                ),
              ),
            );
            return;
          } else if (item.type == NotificationType.message) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở cuộc trò chuyện')),
            );
            return;
          }

          if (item.type == NotificationType.follow &&
              item.senderId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Profile(
                  userId: item.senderId,
                  showBottomNav:
                      true, // giữ thanh điều hướng dưới cùng khi xem qua thông báo
                  initialTab: 3, // đánh dấu Favorites khi trở về
                ),
              ),
            );
            return;
          } else if (item.type == NotificationType.follow) {
            // no sender id available
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở trang cá nhân')),
            );
            return;
          }

          if (item.type == NotificationType.followRequest &&
              item.senderId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Profile(
                  userId: item.senderId,
                  showBottomNav: true,
                  initialTab: 3,
                ),
              ),
            );
            return;
          } else if (item.type == NotificationType.followRequest) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở trang cá nhân')),
            );
            return;
          }

          // Handle trip notifications - navigate to trip page
          if (item.tripId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaochuyendiPage()),
            );
            return;
          }

          // Handle booking notifications - navigate to booking history page
          if (item.bookingId != null || item.bookingType != null) {
            _navigateToBookingPage(item.bookingType);
            return;
          }

          if (item.postId != null) {
            // navigate directly to the post page instead of relying on named
            // routes; this avoids any remaining routing confusion after the
            // prior refactor.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Baiviet(postId: item.postId)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không có bài viết liên quan')),
            );
          }
        },

        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                item.senderId == 'system'
                    ? Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          image: const DecorationImage(
                            image: AssetImage('asset/icon/logo.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 32.5,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            getImageProvider(item.senderPhotoUrl) ??
                            const AssetImage('asset/images/OIP.jpg'),
                      ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, size: 14, color: iconColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${item.senderName} ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF113953),
                          ),
                        ),
                        TextSpan(
                          text: item.message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRelativeTime(item.createdAt),
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  if (item.type == NotificationType.followRequest &&
                      item.senderId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await FirebaseUserService().declineFollowRequest(
                              item.senderId,
                            );
                            await _repo.deleteNotification(item.id);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Xóa'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseUserService().acceptFollowRequest(
                              item.senderId,
                            );
                            await _repo.deleteNotification(item.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB620),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Xác nhận'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _repo.deleteNotification(item.id);
                    } else if (value == 'mark_read') {
                      _repo.markAsRead(item.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Text('Đánh dấu đã đọc'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa thông báo'),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey,
                  ),
                  padding: EdgeInsets.zero,
                ),
                if (!item.isRead) const _UnreadDot(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a notification list from a filtered set of items.
  Widget _buildNotificationList(List<NotificationModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Chưa có thông báo'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItem(items[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if no user, show message instead of firing a query that will fail
    if (_repo.currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Thông báo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: const Center(child: Text('Vui lòng đăng nhập để xem thông báo')),
      );
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Thông báo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
            body: Center(child: Text('Lỗi: $err')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Thông báo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final items = snapshot.data ?? [];
        _latestItems = items;
        
        if (!_initialMarkDone && widget.isActive) {
          _initialMarkDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markCurrentTabAsRead();
          });
        }

        // sort newest first
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // ─── Business account: show tabs ───
        if (_isBusinessAccount && _tabController != null) {
          final personalItems = items
              .where((n) => !_isBizNotification(n))
              .toList();
          final businessItems = _bizNotificationsEnabled
              ? items.where((n) => _isBizNotification(n)).toList()
              : <NotificationModel>[];

          final unreadPersonal = personalItems.where((n) => !n.isRead).length;
          final unreadBusiness = businessItems.where((n) => !n.isRead).length;

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Thông báo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'clear') {
                      _repo.clearAll();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear',
                      child: Text('Xóa tất cả'),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Stack(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF113953),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF113953),
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                      dividerColor: Colors.grey.shade300,
                      dividerHeight: 1,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline, size: 20),
                              const SizedBox(width: 6),
                              const Text('Cá nhân'),
                              if (unreadPersonal > 0)
                                Text(
                                  ' ($unreadPersonal)',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 20),
                              const SizedBox(width: 6),
                              const Text('Kinh doanh'),
                              if (unreadBusiness > 0)
                                Text(
                                  ' ($unreadBusiness)',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // ── Border dọc ngăn cách giữa 2 tab ──
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 10,
                      bottom: 10,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(personalItems),
                _buildNotificationList(businessItems),
              ],
            ),
          );
        }

        // ─── Personal account: single list (original behavior) ───
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              'Thông báo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  // handle menu actions if needed
                  if (value == 'clear') {
                    // example: clear notifications
                    _repo.clearAll();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Xóa tất cả'),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          body: items.isEmpty
              ? const Center(child: Text('Chưa có thông báo'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildItem(items[index]),
                ),
        );
      },
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: const Color(0xFF113953),
      ),
    );
  }
}
