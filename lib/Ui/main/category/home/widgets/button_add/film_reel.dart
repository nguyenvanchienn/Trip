import 'package:flutter/material.dart';

class FilmReelPage extends StatefulWidget {
  const FilmReelPage({super.key});

  @override
  State<FilmReelPage> createState() => _FilmReelPageState();
}

class _FilmReelPageState extends State<FilmReelPage> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createReel() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề cho thước phim')),
      );
      return;
    }

    // For now we simulate creation and return to previous screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Thước phim "$title" đã được tạo')));
    Navigator.pop(context, {'type': 'reel', 'title': title});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thước phim')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiêu đề',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Nhập tiêu đề cho thước phim',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú: chọn video/ảnh từ thư viện sẽ được tích hợp sau.',
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createReel,
                    child: const Text('Tạo thước phim'),
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
