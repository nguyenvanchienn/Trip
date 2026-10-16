import 'package:flutter/material.dart';

class Binhluan extends StatefulWidget {
  const Binhluan({super.key});

  @override
  State<Binhluan> createState() => _BinhluanState();
}

class _BinhluanState extends State<Binhluan> {
  String _selectedPrivacy = "Người theo dõi";
  bool _filterOffensive = true;

  // ===== Icon trái =====
  Widget _leadingIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ===== Tile =====
  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        ListTile(
          leading: _leadingIcon(icon, color),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }

  // ===== BottomSheet =====
  void _showCommentPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),

            const Text(
              "Ai có thể bình luận bài viết của bạn",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            _option("Mọi người"),
            _option("Người theo dõi"),
            _option("Bạn bè"),
            _option("Chỉ mình tôi"),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // ===== Option radio =====
  Widget _option(String text) {
    final bool isSelected = _selectedPrivacy == text;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          title: Text(text, style: const TextStyle(fontSize: 16)),
          onTap: () {
            setState(() => _selectedPrivacy = text);
            Navigator.pop(context);
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Quyền bình luận'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          _tile(
            icon: Icons.comment_outlined,
            title: "Ai có thể bình luận",
            subtitle: _selectedPrivacy,
            onTap: _showCommentPrivacySheet,
          ),

          _tile(
            icon: Icons.shield_outlined,
            title: "Lọc bình luận xúc phạm",
            subtitle: "Tự động ẩn bình luận không phù hợp",
            trailing: Switch(
              value: _filterOffensive,
              onChanged: (v) {
                setState(() => _filterOffensive = v);
              },
            ),
          ),

          _tile(
            icon: Icons.block_outlined,
            title: "Từ khóa bị chặn",
            subtitle: "Quản lý từ khóa bạn không muốn thấy",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
