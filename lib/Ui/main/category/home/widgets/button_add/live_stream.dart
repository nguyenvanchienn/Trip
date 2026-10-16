import 'package:flutter/material.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  final TextEditingController _titleController = TextEditingController();
  bool _isLive = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _startLive() {
    final title = _titleController.text.trim().isEmpty
        ? 'Live không tiêu đề'
        : _titleController.text.trim();
    setState(() => _isLive = true);
    // Simulate starting live – in real app you'd integrate streaming SDK
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LiveViewPage(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phát trực tiếp')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tên buổi phát',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Nhập tiêu đề buổi phát',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ghi chú: tính năng streaming thực tế cần tích hợp SDK'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startLive,
                    child: const Text('Bắt đầu phát trực tiếp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LiveViewPage extends StatelessWidget {
  final String title;
  const LiveViewPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.wifi_tethering, color: Colors.red, size: 64),
            SizedBox(height: 12),
            Text('Đang phát trực tiếp', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
