import 'package:tourn/Ui/main/category/messenge/widgets/ActivateChats.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/CreateGroupChatPage.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/AIbottonchat.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/MenumessengerPage.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/MessageBubble.dart';

// Ghi chú: RecentChats.dart trước đây dùng dữ liệu giả;
// phiên bản Firebase đã tích hợp Firestore qua MessageRepository.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // -----------------------
  // Tham số tinh chỉnh hành vi nút AI
  // -----------------------
  // Ngưỡng quãng vuốt để mở khi đang ở giữa danh sách.
  static const double _expandDistanceThreshold = 120;
  // Ở vị trí top cần vuốt mạnh/dài hơn mới mở nhãn AI.
  static const double _expandDistanceThresholdAtTop = 350;
  // Ngưỡng vuốt để thu gọn nhãn AI.
  static const double _collapseDistanceThreshold = 36;
  // Bỏ qua các delta quá nhỏ để tránh nhiễu khi chạm nhẹ.
  static const double _minDeltaToCount = 5;
  // Ở top cần một nhịp vuốt có lực tối thiểu trước khi cho phép tích lũy mở.
  static const double _minTopSwipeImpulse = 23;
  // Độ trễ trước khi mở nhãn AI.
  static const Duration _expandDelay = Duration(milliseconds: 220);
  // Độ trễ trước khi thu gọn nhãn AI.
  static const Duration _collapseDelay = Duration(milliseconds: 120);
  // Sau khi mở, tự thu gọn lại sau 10 giây.
  static const Duration _autoCollapseAfter = Duration(seconds: 10);

  // -----------------------
  // Dữ liệu/điều khiển cho màn hình chat
  // -----------------------
  // Controller cho ô tìm kiếm bạn bè.
  final TextEditingController _searchController = TextEditingController();
  // Danh sách user đang theo dõi (nguồn dữ liệu gốc).
  List<UserModel> _followingUsers = [];
  // Danh sách user sau khi lọc theo từ khóa tìm kiếm.
  List<UserModel> _filteredUsers = [];
  // Trạng thái đang tìm kiếm hay không.
  bool _isSearching = false;
  // Trạng thái nút AI: mở rộng (hiện nhãn) hoặc thu gọn (chỉ logo).
  bool _showAiLabel = false;

  // -----------------------
  // Biến theo dõi thao tác vuốt để điều khiển mở/đóng nút AI
  // -----------------------
  // Tổng quãng vuốt theo hướng mở (kéo lên).
  double _upSwipeDistance = 0;
  // Tổng quãng vuốt theo hướng đóng (kéo xuống).
  double _downSwipeDistance = 0;
  // Vị trí scroll gần nhất để tính delta trong ScrollUpdateNotification.
  double? _lastScrollPixels;
  // Cờ cho phép mở ở top chỉ sau khi có 1 nhịp vuốt đủ mạnh.
  bool _topExpandArmed = false;

  // -----------------------
  // Timer phục vụ mở/đóng có delay + tự đóng
  // -----------------------
  // Timer delay mở nhãn AI.
  Timer? _expandTimer;
  // Timer delay thu gọn nhãn AI.
  Timer? _collapseTimer;
  // Timer tự thu gọn sau một khoảng thời gian hiển thị.
  Timer? _autoCollapseTimer;

  @override
  void initState() {
    super.initState();
    // Nạp danh sách following để phục vụ tìm kiếm nhanh trong local state.
    _loadFollowingUsers();
    // Lắng nghe thay đổi text để cập nhật kết quả tìm kiếm realtime.
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Hủy timer/controller để tránh leak khi widget bị dispose.
    _expandTimer?.cancel();
    _collapseTimer?.cancel();
    _autoCollapseTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Bắt đầu bộ đếm tự đóng: mở nhãn xong sẽ tự thu gọn sau _autoCollapseAfter.
  void _startAutoCollapseCountdown() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(_autoCollapseAfter, () {
      if (!mounted || !_showAiLabel) return;
      setState(() {
        _showAiLabel = false;
      });
    });
  }

  // Lên lịch mở nhãn AI với độ trễ _expandDelay.
  // Nếu đang mở hoặc đã có timer mở thì bỏ qua.
  void _scheduleExpand() {
    _collapseTimer?.cancel();
    if (_showAiLabel || _expandTimer != null) return;

    _expandTimer = Timer(_expandDelay, () {
      _expandTimer = null;
      if (!mounted || _showAiLabel) return;
      setState(() {
        _showAiLabel = true;
      });
      _startAutoCollapseCountdown();
    });
  }

  // Lên lịch thu gọn nhãn AI với độ trễ _collapseDelay.
  // Đồng thời hủy timer tự đóng vì sắp đóng thủ công.
  void _scheduleCollapse() {
    _expandTimer?.cancel();
    _expandTimer = null;
    _autoCollapseTimer?.cancel();
    if (!_showAiLabel || _collapseTimer != null) return;

    _collapseTimer = Timer(_collapseDelay, () {
      _collapseTimer = null;
      if (!mounted || !_showAiLabel) return;
      setState(() {
        _showAiLabel = false;
      });
    });
  }

  // Lấy danh sách người dùng đang theo dõi từ repository.
  void _loadFollowingUsers() {
    final userRepo = context.read<UserRepository>();
    final currentUserId = userRepo.currentUserId;
    if (currentUserId == null) return;

    userRepo.getFollowing(currentUserId).listen((users) {
      if (!mounted) return;
      setState(() {
        _followingUsers = users;
      });
    });
  }

  // Lọc bạn bè theo từ khóa trong ô tìm kiếm.
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredUsers = [];
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredUsers = _followingUsers.where((user) {
          final name = user.displayName.toLowerCase();
          return name.contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Tin nhắn",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Create new chat / group button (like Messenger)
          IconButton(
            icon: const Icon(
              Icons.edit_square,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            tooltip: 'Tạo nhóm chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupChatPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuPage()),
              );
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Bắt đầu một phiên cuộn mới: reset các bộ đếm quãng vuốt.
          if (notification is ScrollStartNotification) {
            _lastScrollPixels = notification.metrics.pixels;
            _upSwipeDistance = 0;
            _downSwipeDistance = 0;
            _topExpandArmed = false;
            return false;
          }

          if (notification is ScrollUpdateNotification) {
            // Chỉ xử lý thao tác kéo tay của người dùng, bỏ qua animation quán tính.
            if (notification.dragDetails == null) {
              return false;
            }

            final currentPixels = notification.metrics.pixels;
            final previousPixels = _lastScrollPixels ?? currentPixels;
            final delta = currentPixels - previousPixels;
            _lastScrollPixels = currentPixels;

            // Lọc các chuyển động quá nhỏ để vuốt nhẹ/từ từ không kích hoạt nhãn.
            if (delta.abs() < _minDeltaToCount) {
              return false;
            }

            // delta < 0: đang kéo lên (hướng có thể mở nhãn AI).
            if (delta < 0) {
              final isAtTop = notification.metrics.extentBefore <= 0;
              // Ở top: chỉ cho tích lũy mở sau khi người dùng vuốt đủ mạnh ít nhất 1 nhịp.
              if (isAtTop && !_topExpandArmed) {
                if ((-delta) < _minTopSwipeImpulse) {
                  return false;
                }
                _topExpandArmed = true;
              }

              final requiredDistance = isAtTop
                  ? _expandDistanceThresholdAtTop
                  : _expandDistanceThreshold;
              _upSwipeDistance += -delta;
              _downSwipeDistance = 0;
              // Đủ ngưỡng thì lên lịch mở (không mở ngay để tạo cảm giác tự nhiên).
              if (_upSwipeDistance >= requiredDistance) {
                _scheduleExpand();
                _upSwipeDistance = 0;
              }
            } else {
              // Vuốt xuống: ưu tiên thu gọn để đỡ che nội dung.
              _downSwipeDistance += delta;
              _upSwipeDistance = 0;
              if (_downSwipeDistance >= _collapseDistanceThreshold) {
                _scheduleCollapse();
                _downSwipeDistance = 0;
              }
            }
            return false;
          }

          if (notification is OverscrollNotification) {
            // Khi ở biên (đặc biệt là top/empty list), Flutter bắn OverscrollNotification.
            // Ta vẫn cho mở tại top nếu kéo đủ mạnh.
            if (notification.dragDetails == null) {
              return false;
            }

            final overscroll = notification.overscroll;
            if (overscroll < 0) {
              // Tại top/biên: cần 1 nhịp kéo đủ mạnh trước khi cho phép mở nhãn.
              if (!_topExpandArmed) {
                if ((-overscroll) < _minTopSwipeImpulse) {
                  return false;
                }
                _topExpandArmed = true;
              }

              _upSwipeDistance += -overscroll;
              _downSwipeDistance = 0;
              if (_upSwipeDistance >= _expandDistanceThresholdAtTop) {
                _scheduleExpand();
                _upSwipeDistance = 0;
              }
            } else if (overscroll > 0) {
              _downSwipeDistance += overscroll;
              _upSwipeDistance = 0;
              if (_downSwipeDistance >= _collapseDistanceThreshold) {
                _scheduleCollapse();
                _downSwipeDistance = 0;
              }
            }
            return false;
          }

          if (notification is ScrollEndNotification) {
            // Kết thúc cuộn: reset trạng thái tích lũy cho lần vuốt kế tiếp.
            _upSwipeDistance = 0;
            _downSwipeDistance = 0;
            _topExpandArmed = false;
          }
          return false;
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Tìm kiếm bạn bè...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    if (_isSearching)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    else
                      const Icon(
                        Icons.search,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                  ],
                ),
              ),
            ),
            if (_isSearching)
              _buildSearchResults()
            else ...[
              const ActivateChats(),
              const FirebaseRecentChats(),
            ],
          ],
        ),
      ),
      floatingActionButton: Padding(
        // Giữ nút AI nằm phía trên thanh điều hướng nổi ở dưới.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: InkWell(
          // Chạm vào nút để mở bottom sheet chat AI.
          onTap: () {
            buildBottomSheet(context);
          },
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            // Mở nhanh hơn, đóng chậm hơn để cảm giác mềm mại.
            duration: Duration(milliseconds: _showAiLabel ? 260 : 420),
            curve: Curves.easeOutCubic,
            height: 56,
            width: _showAiLabel ? 172 : 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            // Cắt phần con khi animate để tránh tràn tạm thời lúc đổi kích thước.
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 0, 0),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 0, 0, 0),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        top: 4,
                        bottom: 4,
                        right: 5,
                      ),
                      child: Image.asset(
                        "asset/icon/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: _showAiLabel ? 260 : 420),
                  curve: Curves.easeOutCubic,
                  // Animate khoảng cách giữa logo và nhãn theo trạng thái mở/thu.
                  width: _showAiLabel ? 10 : 0,
                ),
                ClipRect(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: _showAiLabel ? 260 : 420),
                    curve: Curves.easeOutCubic,
                    // Animate chiều rộng nhãn (thay vì ẩn/hiện đột ngột) để tránh tràn Row.
                    width: _showAiLabel ? 106 : 0,
                    alignment: Alignment.centerLeft,
                    child: AnimatedOpacity(
                      duration: Duration(
                        milliseconds: _showAiLabel ? 180 : 300,
                      ),
                      // Làm mờ dần khi hiện/ẩn để chuyển động mượt hơn.
                      opacity: _showAiLabel ? 1 : 0,
                      child: const Text(
                        'Hỏi Trip AI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Không tìm thấy bạn bè nào',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: _filteredUsers.map((user) {
        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : const AssetImage('asset/images/OIP.jpg') as ImageProvider,
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            isUserOnline(user.isOnline, user.lastSeen)
                ? 'Đang hoạt động'
                : formatLastSeen(user.lastSeen, false),
            style: TextStyle(
              color: isUserOnline(user.isOnline, user.lastSeen)
                  ? Colors.green
                  : Colors.grey,
              fontSize: 13,
            ),
          ),
          trailing: isUserOnline(user.isOnline, user.lastSeen)
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () async {
            _searchController.clear();
            final msgRepo = context.read<MessageRepository>();
            final userRepo = context.read<UserRepository>();
            final currentUser = await userRepo.getCurrentUser();

            final conversation = await msgRepo.getOrCreatePrivateConversation(
              otherUserId: user.uid,
              otherUserName: user.displayName,
              otherUserPhoto: user.photoUrl,
              currentUserName: currentUser?.displayName,
              currentUserPhoto: currentUser?.photoUrl,
            );

            if (conversation != null && mounted) {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => FirebaseChatPage(
                    conversationId: conversation.id,
                    displayName: user.displayName,
                    displayPhoto: user.photoUrl,
                  ),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }
}
