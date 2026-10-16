import 'package:flutter/material.dart';

class Danhsachdafollow extends StatefulWidget {
  const Danhsachdafollow({super.key});

  @override
  State<Danhsachdafollow> createState() => _DanhsachdafollowState();
}

class _DanhsachdafollowState extends State<Danhsachdafollow> {
  String _selectedPrivacy = "Mọi người";

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
    VoidCallback? onTap,
  }) {
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        ListTile(
          leading: _leadingIcon(icon, color),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }

  // ===== BottomSheet =====
  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            const Text(
              "Ai có thể xem danh sách bạn đã follow",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
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

  Widget _option(String text) {
    final bool isSelected = _selectedPrivacy == text;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          title: Text(text),
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
        title: const Text("Danh sách đã follow"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          _tile(
            icon: Icons.visibility_outlined,
            title: "Ai có thể xem danh sách follow",
            subtitle: _selectedPrivacy,
            onTap: _showPrivacySheet,
          ),
        ],
      ),
    );
  }
}
