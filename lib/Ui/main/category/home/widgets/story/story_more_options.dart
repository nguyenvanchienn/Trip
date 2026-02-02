import 'package:flutter/material.dart';

void showStoryMoreOptions({
  required BuildContext context,
  required String friendName,
  required bool isSaved,
  required VoidCallback onToggleSave,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _MoreOptionItem(
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                label: isSaved ? 'Đã lưu' : 'Lưu',
                onTap: () {
                  Navigator.pop(context);
                  onToggleSave();
                },
              ),
              _MoreOptionItem(
                icon: Icons.flag_outlined,
                label: 'Báo cáo',
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
              _MoreOptionItem(
                icon: Icons.block,
                label: 'Chặn',
                onTap: () {
                  Navigator.pop(context);
                  _showBlockDialog(context);
                },
              ),
              _MoreOptionItem(
                icon: Icons.not_interested,
                label: 'Không quan tâm',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sẽ hiển thị ít nội dung tương tự'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MoreOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreOptionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF113953)),
      title: Text(label),
      onTap: onTap,
    );
  }
}

void _showReportDialog(BuildContext context) {
  final reportReasons = [
    'Nội dung spam',
    'Ngôn từ gây thù ghét',
    'Bạo lực hoặc nguy hiểm',
    'Quấy rối hoặc bắt nạt',
    'Thông tin sai lệch',
    'Vi phạm bản quyền',
    'Khác',
  ];
  String? selectedReason;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Báo cáo nội dung'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: reportReasons
                .map(
                  (reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: const Color(0xFF113953),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: selectedReason != null
                ? () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét nội dung này.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF113953),
            ),
            child: const Text(
              'Gửi báo cáo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showBlockDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chặn người dùng?'),
      content: const Text(
        'Người này sẽ không thể:\n\n'
        '• Xem hồ sơ của bạn\n'
        '• Gửi tin nhắn cho bạn\n'
        '• Bình luận về bài viết của bạn\n\n'
        'Bạn cũng sẽ không thấy nội dung của họ.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã chặn người dùng'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Chặn', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
