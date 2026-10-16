import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tourn/Ui/main/widget/custom_bottom_nav_bar.dart';
import 'package:tourn/Ui/main/category/favorites/favorites_page.dart';
import 'package:tourn/Ui/main/category/home/Home.dart';
import 'package:tourn/Ui/main/category/messenge/mail_page.dart';
import 'package:tourn/Ui/main/category/map/map_page.dart';
import 'package:tourn/Ui/main/category/menu/Menu.dart';
import 'package:tourn/Ui/main/category/menu/pages/Menu_page.dart';
import 'package:tourn/Ui/main/category/menu/pages/Menu_drawer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/domain/notification_repository/notification_repository.dart';
import 'package:tourn/models/conversation_model.dart';
import 'package:tourn/models/notification_model.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';

class Mainpage extends StatefulWidget {
  final int initialTab; // Tab khởi đầu

  const Mainpage({super.key, this.initialTab = 0});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  static const double _navHideDistance = 140;

  // Danh sách các trang để hiển thị khi chọn từ thanh điều hướng dưới cùng
  late int _currentPage; // Sử dụng late để khởi tạo trong initState
  double _bottomNavProgress = 1;
  int _homeReloadVersion = 0;
  int _mailReloadVersion = 0;
  int _favoritesReloadVersion = 0;

  late final MapPageController _mapPageController;
  late final MenuPageController _menuPageController;

  late Stream<int> _mailCountStream;
  late Stream<int> _notifCountStream;

  // internal helpers for computing badge count without restricted chats
  StreamController<int>? _mailCountController;
  StreamSubscription<List<ConversationModel>>? _convSub;
  StreamSubscription<List<UserModel>>? _restrictSub;
  Set<String> _restrictedIds = {};
  List<ConversationModel> _lastConvs = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialTab; // Sử dụng initialTab
    _mapPageController = MapPageController();
    _menuPageController = MenuPageController();
  }

  List<Widget> _buildPages() {
    return [
      Home(
        key: ValueKey('home_$_homeReloadVersion'),
        isFirsTimeinstallApp: true,
        onBottomNavVisibilityChanged: _handleBottomNavVisibility,
        bottomNavProgress: _bottomNavProgress,
      ),
      mailpage(key: ValueKey('mail_$_mailReloadVersion')),
      mappage(controller: _mapPageController),
      favorites(
        key: ValueKey('favorites_$_favoritesReloadVersion'),
        isActive: _currentPage == 3,
      ),
      Menu(controller: _menuPageController),
    ];
  }

  void _handleReselectCurrentTab(int index) {
    switch (index) {
      case 0:
        setState(() {
          _homeReloadVersion++;
          _bottomNavProgress = 1;
        });
        break;
      case 1:
        setState(() {
          _mailReloadVersion++;
          _bottomNavProgress = 1;
        });
        break;
      case 2:
        _mapPageController.recenterToCurrentLocation();
        break;
      case 3:
        setState(() {
          _favoritesReloadVersion++;
          _bottomNavProgress = 1;
        });
        break;
      case 4:
        _menuPageController.scrollToTop();
        break;
    }
  }

  void _handleBottomNavVisibility(bool visible) {
    if (!mounted) return;
    final next = visible ? 1.0 : 0.0;
    if ((_bottomNavProgress - next).abs() < 0.001) return;
    setState(() {
      _bottomNavProgress = next;
    });
  }

  bool _handleRootScrollNotification(ScrollNotification notification) {
    if (_currentPage != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta.abs() < 0.5) {
        return false;
      }

      // delta > 0: feed goes down, hide nav gradually.
      // delta < 0: feed goes up, show nav gradually.
      final next = (_bottomNavProgress - (delta / _navHideDistance)).clamp(
        0.0,
        1.0,
      );
      if ((next - _bottomNavProgress).abs() > 0.001) {
        setState(() {
          _bottomNavProgress = next;
        });
      }
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.forward &&
          _bottomNavProgress > 0.85) {
        _handleBottomNavVisibility(true);
      } else if (notification.direction == ScrollDirection.reverse &&
          _bottomNavProgress < 0.15) {
        _handleBottomNavVisibility(false);
      }
    }

    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final msgRepo = context.read<MessageRepository>();
    debugPrint('[MainPage] didChangeDependencies called');

    // badge for unread mail should ignore conversations where we've
    // restricted the other user.  rather than altering the service we
    // compose the count manually by listening to both the conversation
    // stream and the restricted-user stream, then recalculating whenever
    // either changes.
    _mailCountController ??= StreamController<int>.broadcast();
    _mailCountStream = _mailCountController!.stream;

    _convSub ??= msgRepo.getConversations().listen(
      (convs) {
        debugPrint('[MainPage] Conversations loaded: ${convs.length}');
        _lastConvs = convs;
        _recomputeMailCount(msgRepo.currentUserId);
      },
      onError: (error) {
        debugPrint('[MainPage] Error loading conversations: $error');
        // Continue with empty list if index is not ready
        _lastConvs = [];
        _recomputeMailCount(msgRepo.currentUserId);
      },
    );

    _restrictSub ??= FirebaseUserService().getRestrictedUsers().listen((list) {
      debugPrint('[MainPage] Restricted users loaded: ${list.length}');
      final newSet = list.map((u) => u.uid).toSet();
      // mark any newly restricted conversations read so their unread
      // counters don't linger (and the badge will never flash for them).
      final added = newSet.difference(_restrictedIds);
      if (added.isNotEmpty && msgRepo.currentUserId != null) {
        for (final c in _lastConvs) {
          final other = c.participants.firstWhere(
            (id) => id != msgRepo.currentUserId,
            orElse: () => '',
          );
          if (other.isNotEmpty && added.contains(other)) {
            msgRepo.markAsRead(c.id);
          }
        }
      }
      _restrictedIds = newSet;
      _recomputeMailCount(msgRepo.currentUserId);
    });

    final notifRepo = context.read<NotificationRepository>();
    _notifCountStream = notifRepo.getNotifications().map((items) {
      int count = 0;
      for (final item in items) {
        if (_isBizNotification(item)) continue;
        if (!item.isRead) count += 1;
      }
      return count;
    });
    debugPrint('[MainPage] Streams initialized');
  }

  void _recomputeMailCount(String? currentUserId) {
    if (currentUserId == null) {
      _mailCountController?.add(0);
      return;
    }
    int total = 0;
    for (final c in _lastConvs) {
      if (c.deletedFor.contains(currentUserId)) continue;
      if (c.type == ConversationType.private &&
          c.participants.contains('trip_ai')) {
        continue;
      }
      final other = c.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (other.isNotEmpty && _restrictedIds.contains(other)) continue;
      total += c.unreadCount[currentUserId] ?? 0;
    }
    _mailCountController?.add(total);
  }

  bool _isBizNotification(NotificationModel item) {
    if (item.isBusinessNotification) return true;
    if (item.type == NotificationType.businessAccount) return true;
    if (item.bookingId != null || item.bookingType != null) return true;
    return false;
  }

  Widget _iconWithBadge(Widget icon, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      initialData: 0,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        if (count <= 0) return icon;
        final text = count > 9 ? '9+' : '$count';
        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _mailCountController?.close();
    _convSub?.cancel();
    _restrictSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy locale hiện tại để trigger rebuild khi thay đổi ngôn ngữ
    final _ = context.locale;

    // prevent the user from popping the main page (swipe‑back / system back button)
    return PopScope(
      canPop: false,
      child: Scaffold(
        endDrawer: const MenuDrawer(),
        extendBody: true,
        backgroundColor: const Color(
          0xFFF0F0F0,
        ), // Changed background to light gray like the image
        // keep pages alive when switching tabs
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _handleRootScrollNotification,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: IndexedStack(
                  index: _currentPage,
                  children: _buildPages(),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOutCubic,
                offset: Offset(0, (1 - _bottomNavProgress) * 1.2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 90),
                  opacity: _bottomNavProgress,
                  child: IgnorePointer(
                    ignoring: _bottomNavProgress < 0.05,
                    child: CustomBottomNavBar(
                      selectedIndex: _currentPage,
                      onItemTapped: (index) {
                        if (index == _currentPage) {
                          _handleReselectCurrentTab(index);
                          return;
                        }
                        setState(() {
                          _currentPage = index;
                          _bottomNavProgress = 1;

                          // Force a rebuild whenever entering these tabs so
                          // returning from a pushed page (e.g. Profile) also
                          // refreshes their data/UI.
                          if (index == 0) {
                            _homeReloadVersion++;
                          } else if (index == 1) {
                            _mailReloadVersion++;
                          } else if (index == 3) {
                            _favoritesReloadVersion++;
                          }
                        });
                      },
                      items: <BottomNavigationBarItem>[
                        // Thêm các mục vào thanh điều hướng dưới cùng
                        BottomNavigationBarItem(
                          icon: const Icon(
                            Icons.home_outlined,
                            color: Colors.grey,
                          ),
                          activeIcon: const Icon(
                            Icons.home,
                            color: Colors.black,
                          ),
                          label: "home".tr(),
                        ),
                        BottomNavigationBarItem(
                          icon: _iconWithBadge(
                            const Icon(Icons.mail_outline, color: Colors.grey),
                            _mailCountStream,
                          ),
                          activeIcon: _iconWithBadge(
                            const Icon(Icons.mail, color: Colors.black),
                            _mailCountStream,
                          ),
                          label: "mail".tr(),
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(
                            Icons.map_outlined,
                            color: Colors.grey,
                          ),
                          activeIcon: const Icon(
                            Icons.map,
                            color: Colors.black,
                          ),
                          label: "map".tr(),
                        ),
                        BottomNavigationBarItem(
                          icon: _iconWithBadge(
                            const Icon(
                              Icons.favorite_border,
                              color: Colors.grey,
                            ),
                            _notifCountStream,
                          ),
                          activeIcon: _iconWithBadge(
                            const Icon(Icons.favorite, color: Colors.black),
                            _notifCountStream,
                          ),
                          label: "favorite".tr(),
                        ),
                        BottomNavigationBarItem(
                          icon: const Icon(
                            Icons.person_outline,
                            color: Colors.grey,
                          ),
                          activeIcon: const Icon(
                            Icons.person,
                            color: Colors.black,
                          ),
                          label: "menu".tr(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
