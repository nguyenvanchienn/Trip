import 'package:flutter/material.dart';

class Baiviet extends StatefulWidget {
  final Map<String, dynamic>? post;
  const Baiviet({super.key, this.post});

  @override
  State<Baiviet> createState() => _BaivietState();
}

class _BaivietState extends State<Baiviet> {
  late Map<String, dynamic> _post;
  late List<Map<String, dynamic>> _comments;
  final TextEditingController _commentController = TextEditingController();
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _post =
        widget.post ??
        {
          'author': 'Nguyễn Chiến',
          'avatar': 'asset/images/anh-mo-ta.jpg',
          'visibility': 0,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
          'text':
              'Hôm nay mình đã khám phá một nơi rất đẹp — khung cảnh tuyệt vời và đồ ăn ngon. Mọi người nên thử khi có dịp!',
          'image': 'asset/images/anh-mo-ta.jpg',
          'likes': 128,
          'comments': 2,
          'shares': 6,
        };

    _comments = [
      {'author': 'Chiến', 'text': 'Đẹp quá!', 'time': '1 Phút'},
      {
        'author': 'Hiển',
        'text': 'Cho mình hỏi chỗ này ở đâu?',
        'time': '30 Giây',
      },
      {'author': 'Vương', 'text': 'Chú chó đẹp quá', 'time': '5 Phút'},
    ];
    _liked = false;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _post['likes'] = (_post['likes'] as int) + (_liked ? 1 : -1);
    });
  }

  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _comments.insert(0, {
        'author': 'Bạn',
        'text': text.trim(),
        'time': 'Vừa xong',
      });
      _post['comments'] = (_post['comments'] as int) + 1;
      _commentController.clear();
    });
  }

  IconData _visibilityIcon(int v) {
    switch (v) {
      case 0:
        return Icons.public;
      case 1:
        return Icons.lock;
      case 2:
        return Icons.people;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _post['image'] as String?;
    final likes = _post['likes'] as int? ?? 0;
    final commentsCount = _post['comments'] as int? ?? 0;
    final shares = _post['shares'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                _post['avatar'] as String,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post['author'] as String,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(_post['timestamp'] as DateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _visibilityIcon(_post['visibility'] as int? ?? 0),
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            //menu options
            onSelected: (v) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Chọn: $v')));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Báo cáo', child: Text('Báo cáo')),
              const PopupMenuItem(value: 'Chia sẻ', child: Text('Chia sẻ')),
              const PopupMenuItem(
                value: 'Sao chép link',
                child: Text('Sao chép link'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_post['text'] as String?) ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (image != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(),
                              body: Center(
                                child: InteractiveViewer(
                                  child: Image.asset(image),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _liked ? Icons.favorite : Icons.favorite_border,
                              color: _liked ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text('$likes'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      InkWell(
                        onTap: () {
                          // scroll to comments (not implemented: simple UX)
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mode_comment_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text('$commentsCount'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Icon(Icons.share_outlined, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('$shares'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Bình luận',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._comments.map((c) => _buildCommentTile(c)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Icon tải ảnh
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          // Hiện thông báo chưa bật chức năng
                          const SnackBar(
                            content: Text('Chức năng tải ảnh chưa được bật'),
                          ),
                        );
                      },
                    ),

                    // Icon GIF
                    IconButton(
                      icon: const Icon(Icons.gif),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chèn GIF chưa được bật'),
                          ),
                        );
                      },
                    ),

                    // Ô nhập comment
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Viết bình luận...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: _addComment,
                      ),
                    ),

                    // Nút gửi
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () => _addComment(_commentController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('asset/images/anh-mo-ta.jpg'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c['author'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      c['time'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c['text'] ?? ''),
                const SizedBox(height: 8),
                if ((c['attachments'] as List<dynamic>?)?.isNotEmpty ?? false)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (c['attachments'] as List<dynamic>).map<Widget>((
                      a,
                    ) {
                      final path = a as String;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          path,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} Phút';
    if (diff.inHours < 24) return '${diff.inHours} Giờ';
    return '${diff.inDays} Ngày';
  }
}
