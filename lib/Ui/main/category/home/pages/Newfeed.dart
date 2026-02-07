// đây là file chứa code của phần trang tin tức trong phần home
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile.dart';
import 'package:tourn/Ui/main/category/home/widgets/post_actions.dart';

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

  void _toggleLike() {
    setState(() {
      final liked = (_post['liked'] as bool?) ?? false;
      if (!liked) {
        _post['liked'] = true;
        _post['likes'] = (_post['likes'] as int) + 1;
        _post['timestamp'] = (_post['timestamp'] as DateTime).subtract(
          const Duration(hours: 1),
        );
      } else {
        _post['liked'] = false;
        _post['likes'] = (_post['likes'] as int) - 1;
      }
    });
  }

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

  Future<void> _loadMore() async {
    // Tải thêm bài viết
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    if (!mounted) return;
    setState(() {});
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
            onShare: _incrementShares,
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
              final reason = await showDialog<String>(
                context: context,
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
                  context,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const profile(),
                        ),
                      );
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const profile(),
                                    ),
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
                                      : Colors.blue[700],
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
                  InkWell(
                    onTap: onLike ?? () {},
                    child: Row(
                      children: [
                        Icon(
                          (post['liked'] as bool? ?? false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: (post['liked'] as bool? ?? false)
                              ? Colors.red
                              : Colors.blue[700],
                        ),
                        const SizedBox(width: 6),
                        Text('${post['likes']}'),
                      ],
                    ),
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
            return DraggableScrollableSheet(
              initialChildSize:
                  0.6, // Kích thước ban đầu (40% chiều cao màn hình)
              minChildSize:
                  0.4, // Kích thước tối thiểu (20% chiều cao màn hình)
              maxChildSize: (maxSheetHeight / constraints.maxHeight).clamp(
                0.0,
                1.0,
              ),
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
