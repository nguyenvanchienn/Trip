// đây là file chứa code của phần trang chủ profile trong trang profile
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';
import 'package:tourn/Ui/main/category/home/widgets/edit_post_page.dart';

class Newfeedprofile extends StatefulWidget {
  const Newfeedprofile({super.key});

  @override
  State<Newfeedprofile> createState() => _NewfeedprofileState();
}

class _NewfeedprofileState extends State<Newfeedprofile> {
  final int _hours = 2; // Số giờ đã trôi qua kể từ khi bài viết được đăng
  Timer? _timer; // Timer để cập nhật thời gian trôi qua
  final int _visibility = 0; // 0: public, 1: private, 2: friends, 3: custom
  bool _isLoadingMore = false;

  // Danh sách bài viết
  List<Map<String, dynamic>> _posts = [];
  int? _pinnedPostIndex; // Index của bài viết được ghim

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
    // Tạo danh sách bài viết mẫu
    _posts = List.generate(
      8,
      (index) => {
        'id': index,
        'author': 'Nguyễn Hữu Hiển',
        'timestamp': DateTime.now().subtract(Duration(hours: _hours + index)),
        'icon': _iconFor(_visibility),
        'liked': false,
        'avatar': 'asset/images/anh-mo-ta.jpg',
        'following': false,
        'text':
            'Hôm nay mình đã khám phá một nơi rất đẹp — khung cảnh tuyệt vời và đồ ăn ngon. Mọi người nên thử khi có dịp! #$index',
        'image': 'asset/images/anh-mo-ta.jpg',
        'likes': 128 + index,
        'comments': 24 + index,
        'shares': 6 + index,
        'isPinned': false,
      },
    );

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _toggleLike(int index) {
    setState(() {
      final post = _posts[index];
      final liked = (post['liked'] as bool?) ?? false;
      if (!liked) {
        post['liked'] = true;
        post['likes'] = (post['likes'] as int) + 1;
      } else {
        post['liked'] = false;
        post['likes'] = (post['likes'] as int) - 1;
      }
    });
  }

  void _incrementComments(int index) {
    setState(() {
      _posts[index]['comments'] = (_posts[index]['comments'] as int) + 1;
    });
  }

  void _incrementShares(int index) {
    setState(() {
      _posts[index]['shares'] = (_posts[index]['shares'] as int) + 1;
    });
  }

  void _toggleFollow(int index) {
    setState(() {
      _posts[index]['following'] =
          !(_posts[index]['following'] as bool? ?? false);
    });
  }

  void _pinPost(int index) {
    setState(() {
      // Bỏ ghim bài cũ nếu có
      if (_pinnedPostIndex != null) {
        _posts[_pinnedPostIndex!]['isPinned'] = false;
      }

      if (_pinnedPostIndex == index) {
        // Bỏ ghim
        _pinnedPostIndex = null;
        _posts[index]['isPinned'] = false;
      } else {
        // Ghim bài mới
        _pinnedPostIndex = index;
        _posts[index]['isPinned'] = true;
      }
    });
  }

  void _deletePost(int index) {
    setState(() {
      if (_pinnedPostIndex == index) {
        _pinnedPostIndex = null;
      } else if (_pinnedPostIndex != null && _pinnedPostIndex! > index) {
        _pinnedPostIndex = _pinnedPostIndex! - 1;
      }
      _posts.removeAt(index);
    });
  }

  void _editPost(int index, Map<String, dynamic> updatedPost) {
    setState(() {
      // Cập nhật nội dung bài viết
      _posts[index]['text'] = updatedPost['content'] ?? _posts[index]['text'];
      _posts[index]['privacy'] =
          updatedPost['privacy'] ?? _posts[index]['privacy'];
      _posts[index]['allowComments'] =
          updatedPost['allowComments'] ?? _posts[index]['allowComments'];

      // Cập nhật ảnh nếu có
      final images = updatedPost['images'] as List?;
      if (images != null && images.isNotEmpty) {
        _posts[index]['image'] = images.first;
      } else {
        _posts[index]['image'] = null;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      final currentLength = _posts.length;
      _posts.addAll(
        List.generate(
          5,
          (i) => {
            'id': currentLength + i,
            'author': 'Nguyễn Hữu Hiển',
            'timestamp': DateTime.now().subtract(
              Duration(hours: _hours + currentLength + i),
            ),
            'icon': _iconFor(_visibility),
            'liked': false,
            'avatar': 'asset/images/anh-mo-ta.jpg',
            'following': false,
            'text': 'Bài viết mới #${currentLength + i}',
            'image': 'asset/images/anh-mo-ta.jpg',
            'likes': 50 + i,
            'comments': 10 + i,
            'shares': 3 + i,
            'isPinned': false,
          },
        ),
      );
      _isLoadingMore = false;
    });
  }

  // Lấy danh sách bài viết đã sắp xếp (bài ghim lên đầu)
  List<MapEntry<int, Map<String, dynamic>>> _getSortedPosts() {
    final indexed = _posts.asMap().entries.toList();
    indexed.sort((a, b) {
      final aPinned = a.value['isPinned'] as bool? ?? false;
      final bPinned = b.value['isPinned'] as bool? ?? false;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });
    return indexed;
  }

  @override
  void dispose() {
    // Hủy timer khi widget bị hủy để tránh rò rỉ bộ nhớ
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedPosts = _getSortedPosts();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 120 &&
            !_isLoadingMore) {
          _loadMore();
        }
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            ...sortedPosts.map((entry) {
              final originalIndex = entry.key;
              final post = entry.value;
              final isPinned = post['isPinned'] as bool? ?? false;

              return PostCard(
                post: post,
                isPinned: isPinned,
                onLike: () => _toggleLike(originalIndex),
                onComment: () => _incrementComments(originalIndex),
                onShare: () => _incrementShares(originalIndex),
                onFollow: () => _toggleFollow(originalIndex),
                onPin: () => _pinPost(originalIndex),
                onDelete: () => _deletePost(originalIndex),
                onEdit: (updatedPost) => _editPost(originalIndex, updatedPost),
              );
            }),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isPinned;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final Function(Map<String, dynamic>)? onEdit;

  const PostCard({
    required this.post,
    this.isPinned = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onFollow,
    this.onPin,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final int hours = DateTime.now()
        .difference(post['timestamp'] as DateTime)
        .inHours;
    return Column(
      children: [
        // Hiển thị badge "Đã ghim" nếu bài viết được ghim
        if (isPinned)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.push_pin, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Bài viết đã ghim',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        Card(
          margin: EdgeInsets.only(
            left: 0,
            right: 0,
            top: isPinned ? 0 : 8,
            bottom: 8,
          ),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPinned ? 0 : 12),
            side: BorderSide(
              color: isPinned ? Colors.blue.shade200 : Colors.grey.shade300,
              width: isPinned ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {
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
                          HapticFeedback.vibrate();
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
                                      HapticFeedback.vibrate();
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
                                      color:
                                          (post['following'] as bool? ?? false)
                                          ? Colors.grey[200]
                                          : Colors.blue[700],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (post['following'] as bool? ?? false)
                                          ? 'Đang theo dõi'
                                          : 'Theo dõi',
                                      style: TextStyle(
                                        color:
                                            (post['following'] as bool? ??
                                                false)
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
                            isPinned: isPinned,
                            onPin: onPin,
                            onDelete: onDelete,
                            onEdit: onEdit,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
        ),
      ],
    );
  }
}

void buildBottomSheet(
  BuildContext context, {
  required Map<String, dynamic> post,
  bool isPinned = false,
  VoidCallback? onPin,
  VoidCallback? onDelete,
  Function(Map<String, dynamic>)? onEdit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (sheetContext) {
      return _PostOptionsSheet(
        post: post,
        isPinned: isPinned,
        onPin: onPin,
        onDelete: onDelete,
        onEdit: onEdit,
      );
    },
  );
}

class _PostOptionsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isPinned;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final Function(Map<String, dynamic>)? onEdit;

  const _PostOptionsSheet({
    required this.post,
    this.isPinned = false,
    this.onPin,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<_PostOptionsSheet> createState() => _PostOptionsSheetState();
}

class _PostOptionsSheetState extends State<_PostOptionsSheet> {
  late bool _isPinned;
  int _privacyOption = 0; // 0: public, 1: friends, 2: only me
  int _commentOption = 0; // 0: everyone, 1: friends, 2: off

  @override
  void initState() {
    super.initState();
    _isPinned = widget.isPinned;
  }

  String _getPrivacyText() {
    switch (_privacyOption) {
      case 0:
        return 'Công khai';
      case 1:
        return 'Bạn bè';
      case 2:
        return 'Chỉ mình tôi';
      default:
        return 'Công khai';
    }
  }

  IconData _getPrivacyIcon() {
    switch (_privacyOption) {
      case 0:
        return Icons.public;
      case 1:
        return Icons.people;
      case 2:
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  String _getCommentText() {
    switch (_commentOption) {
      case 0:
        return 'Mọi người';
      case 1:
        return 'Bạn bè';
      case 2:
        return 'Tắt bình luận';
      default:
        return 'Mọi người';
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn quyền riêng tư'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blue),
              title: const Text('Công khai'),
              subtitle: const Text('Mọi người có thể xem'),
              trailing: _privacyOption == 0
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _privacyOption = 0);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đặt quyền riêng tư: Công khai'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.orange),
              title: const Text('Bạn bè'),
              subtitle: const Text('Chỉ bạn bè có thể xem'),
              trailing: _privacyOption == 1
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _privacyOption = 1);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đặt quyền riêng tư: Bạn bè'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.red),
              title: const Text('Chỉ mình tôi'),
              subtitle: const Text('Chỉ bạn có thể xem'),
              trailing: _privacyOption == 2
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _privacyOption = 2);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đặt quyền riêng tư: Chỉ mình tôi'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền bình luận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blue),
              title: const Text('Mọi người'),
              trailing: _commentOption == 0
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _commentOption = 0);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mọi người có thể bình luận')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.orange),
              title: const Text('Bạn bè'),
              trailing: _commentOption == 1
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _commentOption = 1);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chỉ bạn bè có thể bình luận')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.comments_disabled, color: Colors.red),
              title: const Text('Tắt bình luận'),
              trailing: _commentOption == 2
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _commentOption = 2);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã tắt bình luận cho bài viết'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Đóng dialog
              Navigator.pop(parentContext); // Đóng bottom sheet
              // Gọi callback xóa bài viết
              widget.onDelete?.call();
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa bài viết'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAlbumDialog() {
    final parentContext = context;
    final albums = [
      'Ảnh chụp màn hình',
      'Du lịch',
      'Gia đình',
      'Bạn bè',
      'Công việc',
    ];
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm vào album'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tạo album mới
              ListTile(
                leading: const Icon(
                  Icons.add_photo_alternate,
                  color: Colors.blue,
                ),
                title: const Text('Tạo album mới'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showCreateAlbumDialog();
                },
              ),
              const Divider(),
              // Danh sách album hiện có
              ...albums.map(
                (album) => ListTile(
                  leading: const Icon(Icons.photo_album, color: Colors.grey),
                  title: Text(album),
                  onTap: () {
                    Navigator.pop(dialogContext); // Đóng dialog
                    Navigator.pop(parentContext); // Đóng bottom sheet
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Đã thêm vào album "$album"')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAlbumDialog() {
    final parentContext = context;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo album mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên album',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext); // Đóng dialog
                Navigator.pop(parentContext); // Đóng bottom sheet
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã tạo album "${controller.text}" và thêm bài viết',
                    ),
                  ),
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxSheetHeight = 420;
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: (maxSheetHeight / constraints.maxHeight).clamp(
              0.0,
              1.0,
            ),
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
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
                    // Ghim bài viết
                    InkWell(
                      onTap: () {
                        final sheetContext = context;
                        Navigator.pop(sheetContext);
                        // Gọi callback để ghim/bỏ ghim bài viết ở parent
                        widget.onPin?.call();
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isPinned
                                  ? 'Đã bỏ ghim bài viết'
                                  : 'Đã ghim bài viết',
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: Icon(
                          _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: _isPinned ? Colors.blue : Colors.black,
                        ),
                        title: Text(
                          _isPinned ? 'Bỏ ghim bài viết' : 'Ghim bài viết',
                        ),
                      ),
                    ),
                    // Chỉnh sửa bài viết
                    InkWell(
                      onTap: () {
                        final sheetContext = context;
                        Navigator.of(sheetContext).pop();
                        Navigator.push(
                          sheetContext,
                          MaterialPageRoute(
                            builder: (context) => EditPostPage(
                              post: {
                                'content': widget.post['text'] ?? '',
                                'name': widget.post['name'] ?? 'Người dùng',
                                'avatar': widget.post['avatar'],
                                'privacy': widget.post['privacy'] ?? 'public',
                                'allowComments':
                                    widget.post['allowComments'] ?? true,
                                'images': widget.post['image'] != null
                                    ? [widget.post['image']]
                                    : <String>[],
                              },
                              onSave: (updatedPost) {
                                // Gọi callback để cập nhật bài viết trong danh sách
                                widget.onEdit?.call(updatedPost);
                              },
                            ),
                          ),
                        );
                      },
                      child: const ListTile(
                        leading: Icon(Icons.edit, color: Colors.black),
                        title: Text("Chỉnh sửa bài viết"),
                      ),
                    ),
                    // Chỉnh sửa quyền riêng tư
                    InkWell(
                      onTap: _showPrivacyDialog,
                      child: ListTile(
                        leading: Icon(_getPrivacyIcon(), color: Colors.black),
                        title: const Text("Chỉnh sửa quyền riêng tư"),
                        subtitle: Text(
                          _getPrivacyText(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    // Chỉnh sửa quyền bình luận
                    InkWell(
                      onTap: _showCommentDialog,
                      child: ListTile(
                        leading: const Icon(Icons.comment, color: Colors.black),
                        title: const Text(
                          "Chỉnh sửa quyền bình luận về bài viết",
                        ),
                        subtitle: Text(
                          _getCommentText(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    // Xóa bài viết
                    InkWell(
                      onTap: _showDeleteDialog,
                      child: const ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          "Xóa bài viết",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    // Thêm vào album
                    InkWell(
                      onTap: _showAlbumDialog,
                      child: const ListTile(
                        leading: Icon(Icons.photo_album, color: Colors.black),
                        title: Text("Thêm vào album"),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
