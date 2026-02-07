import 'package:flutter/material.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];

  @override
  void initState() {
    super.initState();
    _addOption();
    _addOption();
  }

  void _addOption() {
    final c = TextEditingController();
    setState(() => _optionControllers.add(c));
  }

  void _removeOption(int i) {
    setState(() {
      _optionControllers[i].dispose();
      _optionControllers.removeAt(i);
    });
  }

  void _createPoll() {
    final q = _questionController.text.trim();
    final opts = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (q.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập câu hỏi')));
      return;
    }
    if (opts.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cần ít nhất 2 lựa chọn')));
      return;
    }

    final poll = {
      'question': q,
      'options': opts,
      'createdAt': DateTime.now().toIso8601String(),
    };

    Navigator.pop(context, poll);
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt câu hỏi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Câu hỏi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập câu hỏi',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Các lựa chọn',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _optionControllers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Lựa chọn ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_optionControllers.length > 2)
                        IconButton(
                          onPressed: () => _removeOption(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lựa chọn'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _createPoll,
                  child: const Text('Tạo câu hỏi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
