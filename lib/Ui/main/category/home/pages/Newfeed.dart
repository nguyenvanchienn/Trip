// đây là file chứa code của phần trang tin tức trong phần home
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/post_actions.dart';
import 'package:tourn/Ui/main/category/home/widgets/like_button.dart';
import 'package:tourn/Ui/main/category/home/widgets/share_sheet.dart';
import 'package:tourn/domain/post_repository/post_repository.dart';
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tourn/domain/notification_repository/notification_repository.dart';

import 'package:tourn/models/user_model.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';

/// Navigate to a user's profile, warming the Firestore cache if needed.
/// This is a top‑level helper so that both [NewfeedState] and [PostCard]
/// can invoke it without creating a dependency cycle.
// ignore: use_build_context_synchronously
Future<void> navigateToProfile(BuildContext context, String? userId) async {
  // we intentionally capture the context in a local variable and
  // suppress the lint below; callers should still ensure the widget
  // tree is mounted when invoking this helper.
  // ignore: use_build_context_synchronously
  if (userId == null) return;
  // make a local copy to prevent lints about using context across async gaps
  final navigatorContext = context;
  final repo = Provider.of<PostRepository>(navigatorContext, listen: false);
  if (repo is FirestorePostRepository) {
    final cached = repo.getCachedUserPosts(userId);
    if (cached == null || cached.isEmpty) {
      try {
        await repo.getUserPosts(userId).first;
      } catch (_) {}
    }
  }
  Navigator.push(
    navigatorContext,
    MaterialPageRoute(
      builder: (context) =>
          Profile(showBottomNav: true, initialTab: 0, userId: userId),
    ),
  );
}

class Newfeed extends StatefulWidget {
  const Newfeed({super.key});

  @override
  State<Newfeed> createState() => NewfeedState();
}

class NewfeedState extends State<Newfeed> {
  final int _hours = 2; // Số giờ đã trôi qua kể từ khi bài viết được đăng
  late Map<String, dynamic> _post; // Dữ liệu bài viết
  Timer? _timer; // Timer để cập nhật thời gian trôi qua
  final int _visibility = 0; // 0: public, 1: private, 2: friends, 3: custom
  int _itemsCount =
      20; // Số lượng bài viết hiển thị ban đầu (tăng để test scroll)
  bool _isLoadingMore = false;

  // repositories for sharing
  final FirestorePostRepository _postRepository = FirestorePostRepository();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();

  IconData _iconFor(int v) {
    switch (v) {
      case 0:
        return Icons.public;
      case 1:
        return Icons.lock;
      case 2:
        return Icons.people;
      default:
        return Icons.person_add;
    }
  }

  @override
  void initState() {
    super.initState();
    _post = {
      'id': 'demo_post_1', // demo post id
      'authorId': 'currentUser', // sample id for demo
      'author': 'Nguyễn Chiến',
      'timestamp': DateTime.now().subtract(Duration(hours: _hours)),
      'icon': _iconFor(_visibility),

      'liked': false,
      'avatar': 'asset/images/OIP.jpg',
      'following': false,
      'text':
          'Hôm nay mình đã khám phá một nơi rất đẹp — khung cảnh tuyệt vời và đồ ăn ngon. Mọi người nên thử khi có dịp!',
      'image': 'asset/images/anhdemo.jpeg',
      'likes': 128,
      'comments': 24,
      'shares': 6,
    };

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  // like logic is handled inside each PostCard via LikeButton.
  // this method is kept for compatibility but does nothing.
  void _toggleLike() {}

  void _incrementComments() {
    setState(() {
      _post['comments'] = (_post['comments'] as int) + 1;
    });
  }

  void _incrementShares() {
    setState(() {
      _post['shares'] = (_post['shares'] as int) + 1;
    });
  }

  Future<void> _openShareSheet(Map<String, dynamic> post) async {
    final currentId = _postRepository.currentUserId;
    if (currentId == null) return;
    final me = await _userRepository.getUserById(currentId);
    if (me == null) return;

    final ids = me.followers.toSet().intersection(me.following.toSet());
    final List<UserModel> friends = [];
    for (final id in ids) {
      final u = await _userRepository.getUserById(id);
      if (u != null) friends.add(u);
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: friends.map((f) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: f.photoUrl != null && f.photoUrl!.isNotEmpty
                    ? NetworkImage(f.photoUrl!)
                    : null,
                child: f.photoUrl == null || f.photoUrl!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(f.displayName),
              trailing: TextButton(
                child: const Text('Chia sẻ'),
                onPressed: () async {
                  await _postRepository.sharePost(post['id']);
                  try {
                    final repo = context.read<NotificationRepository>();
                    final uid = repo.currentUserId;
                    if (uid != null) {
                      await repo.sendSystemNotification(
                        recipientId: f.uid,
                        senderName: 'Trip',
                        message: 'Một người bạn đã chia sẻ bài viết với bạn.',
                      );
                    }
                  } catch (_) {}
                  if (mounted) {
                    setState(() {
                      _incrementShares();
                    });
                  }
                  Navigator.pop(c); // close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã chia sẻ bài viết!')),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _shareExternal(Map<String, dynamic> post) {
    final text = '${post['author']} vừa đăng: ${post['text'] ?? ''}';
    Share.share(text);
    _incrementShares();
  }

  void _showShareOptions(Map<String, dynamic> post) {
    showFacebookShareSheet(
      context,
      postMap: post,
      postRepository: _postRepository,
      userRepository: _userRepository,
      onShareSuccess: _incrementShares,
    );
  }

  Future<void> _loadMore() async {
    // Tải thêm bài viết
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    if (!mounted) return;
    setState(() {});
    // ignore: use_build_context_synchronously
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _itemsCount += 10; // Tăng số lượng bài viết hiển thị
      _isLoadingMore = false; // Đánh dấu đã tải xong
    });
  }

  // Public method để parent widget có thể gọi
  void loadMoreIfNeeded() {
    if (!_isLoadingMore) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    // Hủy timer khi widget bị hủy để tránh rò rỉ bộ nhớ
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          // Hiển thị loading indicator ở cuối danh sách
          if (index >= _itemsCount) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
            );
          }

          if ((_post['hidden'] as bool? ?? false)) {
            return const SizedBox.shrink();
          }

          return PostCard(
            post: _post,
            onLike: _toggleLike,
            onComment: _incrementComments,
            onShare: () => _showShareOptions(_post),
            onFollow: () {
              if (!mounted) return;
              setState(() {
                _post['following'] = !(_post['following'] as bool? ?? false);
              });
            },
            onNotInterested: () {
              if (!mounted) return;
              setState(() {
                _post['not_interested'] = true;
                _post['hidden'] = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu không quan tâm')),
              );
            },
            onSave: () {
              if (!mounted) return;
              setState(() {
                _post['saved'] = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu hành trình')),
              );
            },
            onHide: () {
              if (!mounted) return;
              setState(() {
                _post['hidden'] = true;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã ẩn bài viết')));
            },
            onReport: () async {
              // capture context before async gap to satisfy lint
              final localContext = context;
              final reason = await showDialog<String>(
                context: localContext,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Báo cáo bài viết'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(ctx, 'Nội dung không phù hợp'),
                      child: const Text('Nội dung không phù hợp'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'Spam/Quảng cáo'),
                      child: const Text('Spam/Quảng cáo'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'Khác'),
                      child: const Text('Khác'),
                    ),
                  ],
                ),
              );
              if (reason != null) {
                ScaffoldMessenger.of(
                  localContext,
                ).showSnackBar(SnackBar(content: Text('Đã báo cáo: $reason')));
              }
            },
            onBlock: () {
              if (!mounted) return;
              setState(() {
                _post['blocked'] = true;
                _post['hidden'] = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã chặn người đăng')),
              );
            },
            onToggleNotify: () {
              if (!mounted) return;
              setState(() {
                _post['notify'] = !(_post['notify'] as bool? ?? false);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    (_post['notify'] as bool? ?? false)
                        ? 'Bật thông báo'
                        : 'Tắt thông báo',
                  ),
                ),
              );
            },
            onUnfollow: () {
              if (!mounted) return;
              setState(() {
                _post['following'] = false;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã bỏ theo dõi')));
            },
          );
        }, childCount: _itemsCount + (_isLoadingMore ? 1 : 0)),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  // Widget hiển thị một bài viết
  final Map<String, dynamic> post; // Dữ liệu bài viết
  final VoidCallback? onLike; // Hàm gọi khi nhấn nút thích
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;

  // Actions
  final VoidCallback? onNotInterested;
  final VoidCallback? onSave;
  final VoidCallback? onHide;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onToggleNotify;
  final VoidCallback? onUnfollow;

  const PostCard({
    // Khởi tạo hằng số với tham số bắt buộc
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onFollow,
    this.onNotInterested,
    this.onSave,
    this.onHide,
    this.onReport,
    this.onBlock,
    this.onToggleNotify,
    this.onUnfollow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final int hours =
        DateTime.now() // Tính khoảng thời gian đã trôi qua
            .difference(post['timestamp'] as DateTime)
            .inHours;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          // Xử lý khi nhấn vào bài viết (nếu cần)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Baiviet()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      navigateToProfile(context, post['authorId'] as String?);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        post['avatar'] as String,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên + nhãn "Theo dõi" màu xanh
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  navigateToProfile(
                                    context,
                                    post['authorId'] as String?,
                                  );
                                },
                                child: Text(
                                  post['author'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: onFollow ?? () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (post['following'] as bool? ?? false)
                                      ? Colors.grey[200]
                                      : const Color(0xFFFFB620),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (post['following'] as bool? ?? false)
                                      ? 'Đang theo dõi'
                                      : 'Theo dõi',
                                  style: TextStyle(
                                    color: (post['following'] as bool? ?? false)
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$hours Phút',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              post['icon'] as IconData,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      buildBottomSheet(
                        context,
                        post: post,
                        onNotInterested: onNotInterested,
                        onSave: onSave,
                        onHide: onHide,
                        onReport: onReport,
                        onBlock: onBlock,
                        onToggleNotify: onToggleNotify,
                        onUnfollow: onUnfollow,
                      );
                    },
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),
            if ((post['text'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  post['text'] as String,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            if (post['image'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    post['image'] as String,
                    fit: BoxFit.cover,
                    height: 260,
                    width: double.infinity,
                  ),
                ),
              ),
            const Divider(height: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Like (icon + count) tappable
                  LikeButton(
                    initialLiked: post['liked'] as bool? ?? false,
                    initialCount: post['likes'] as int,
                    onChanged: (liked) {
                      onLike?.call();
                    },
                  ),
                  const SizedBox(width: 24),

                  // Comments tappable
                  InkWell(
                    onTap: onComment ?? () {},
                    child: Row(
                      children: [
                        Icon(
                          Icons.mode_comment_outlined,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text('${post['comments']}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Shares tappable
                  InkWell(
                    onTap: onShare ?? () {},
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text('${post['shares']}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void buildBottomSheet(
  BuildContext context, {
  required Map<String, dynamic> post,
  VoidCallback? onNotInterested,
  VoidCallback? onSave,
  VoidCallback? onHide,
  VoidCallback? onReport,
  VoidCallback? onBlock,
  VoidCallback? onToggleNotify,
  VoidCallback? onUnfollow,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Cho phép cuộn nội dung
    backgroundColor: Colors.transparent,
    isDismissible: true, // Đảm bảo ấn ra ngoài sẽ đóng
    enableDrag: true, // Cho phép kéo để đóng
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (context) {
      return GestureDetector(
        // Bắt sự kiện chạm ngoài để đóng
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).pop();
        },
        child: LayoutBuilder(
          // Sử dụng LayoutBuilder để lấy kích thước
          builder: (context, constraints) {
            // Tính chiều cao tối đa của nội dung
            final double maxSheetHeight =
                450; // hoặc tự động tính theo nội dung
            final double maxChildSize = (maxSheetHeight / constraints.maxHeight)
                .clamp(0.5, 1.0);
            // initialChildSize phải <= maxChildSize
            final double initialChildSize = maxChildSize.clamp(
              0.4,
              maxChildSize,
            );
            return DraggableScrollableSheet(
              initialChildSize: initialChildSize,
              minChildSize:
                  0.4, // Kích thước tối thiểu (20% chiều cao màn hình)
              maxChildSize: maxChildSize,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    shrinkWrap:
                        true, // Cho phép nội dung co lại theo kích thước
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Use the PostActionsList widget which contains one widget per action
                      PostActionsList(
                        onNotInterested: onNotInterested,
                        onSaveTrip: onSave,
                        onHidePost: onHide,
                        onReportPost: onReport,
                        onBlockUser: onBlock,
                        onToggleNotify: onToggleNotify,
                        onUnfollow: onUnfollow,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}
