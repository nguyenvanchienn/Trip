import 'package:flutter/material.dart';

class Guiphanhoi extends StatefulWidget {
  const Guiphanhoi({super.key});

  @override
  State<Guiphanhoi> createState() => _GuiphanhoiState();
}

class _GuiphanhoiState extends State<Guiphanhoi> {
  // 🔥 GIẢ LẬP USER (sau này bạn thay bằng Firebase hoặc API)
  String username = "Chiến Nguyễn";
  String email = "chien@gmail.com";

  final TextEditingController _content = TextEditingController();
  bool _loading = false;

  void _sendFeedback() async {
    if (_content.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nhập nội dung phản hồi")));
      return;
    }

    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 1)); // giả lập gửi server

    setState(() => _loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã gửi phản hồi ❤️")));

    _content.clear();
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gửi phản hồi"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Thông tin tài khoản",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _infoTile("Tên tài khoản", username, Icons.person_outline),
          _infoTile("Email", email, Icons.email_outlined),

          const SizedBox(height: 20),

          const Text(
            "Nội dung phản hồi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _content,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: "Nhập phản hồi của bạn...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _loading ? null : _sendFeedback,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text("Gửi phản hồi"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Phản hồi của bạn giúp chúng tôi cải thiện ứng dụng tốt hơn ❤️",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
