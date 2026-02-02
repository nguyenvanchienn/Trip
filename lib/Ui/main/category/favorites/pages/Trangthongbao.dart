// ignore: unused_import
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:tourn/Ui/main/category/favorites/pages/Trangthongbao.dart';
// removed unused import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> items = [];
  bool _loading = false; // chống load liên tục

  @override
  void initState() {
    super.initState();
    items = _generateItems(6);
  }

  List<Map<String, dynamic>> _generateItems(int count) {
    return List.generate(count, (index) {
      final type = index % 6; // 6 loại tương tác khác nhau

      String message;
      IconData icon;
      Color iconColor;

      switch (type) {
        case 0: // Like
          message = 'đã thích bài viết của bạn.';
          icon = Icons.favorite;
          iconColor = Colors.red;
          break;
        case 1: // Bình luận
          message = 'đã bình luận về bài viết của bạn: "Bài viết rất hay!"';
          icon = Icons.comment;
          iconColor = const Color.fromARGB(255, 94, 255, 40);
          break;
        case 2: // Nhắc đến
          message = 'đã nhắc đến bạn trong một bình luận.';
          icon = Icons.alternate_email;
          iconColor = Colors.blue;
          break;
        case 3: // Chia sẻ
          message = 'đã chia sẻ bài viết của bạn.';
          icon = Icons.share;
          iconColor = Colors.orange;
          break;
        case 4: // Live
          message = 'đang phát trực tiếp. Tham gia ngay!';
          icon = Icons.live_tv;
          iconColor = Colors.red;
          break;
        case 5: // Theo dõi
          message = 'đã bắt đầu theo dõi bạn.';
          icon = Icons.person_add;
          iconColor = Colors.purple;
          break;
        default:
          message = 'đã tương tác với bài viết của bạn.';
          icon = Icons.notifications;
          iconColor = Colors.grey;
      }

      return {
        'name': 'Nguyễn Chiến',
        'message': message,
        'time': '${2 + index} phút trước',
        'icon': icon,
        'iconColor': iconColor,
        'type': type,
      };
    });
  }

  void _loadMore() {
    if (_loading) return;
    _loading = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        items.addAll(_generateItems(5));
        _loading = false;
      });
    });
  }

  Widget _buildItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, "/baiviet"),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Image.asset(
                    'asset/images/OIP.jpg',
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                  ),
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
                      child: Icon(
                        item['icon'] as IconData,
                        size: 14,
                        color: item['iconColor'] as Color,
                      ),
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
                          text: '${item['name']} ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF113953),
                          ),
                        ),
                        TextSpan(
                          text: item['message'] as String,
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
                    item['time'] as String,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [SizedBox(height: 10), _UnreadDot()],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels ==
              notification.metrics.maxScrollExtent) {
            _loadMore(); // Tải thêm dữ liệu khi cuộn đến cuối
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildItem(items[index]),
        ),
      ),
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
