import 'package:flutter/material.dart';

class Nhacden extends StatefulWidget {
  const Nhacden({super.key});

  @override
  State<Nhacden> createState() => _NhacdenState();
}

class _NhacdenState extends State<Nhacden> {
  String _selected = "Người theo dõi";

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
    VoidCallback? onTap,
  }) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;

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
  void _showMentionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),

            const Text(
              "Ai có thể nhắc đến bạn",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            _option("Mọi người"),
            _option("Người theo dõi"),
            _option("Bạn bè"),
            _option("Không ai"),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // ===== Option radio =====
  Widget _option(String text) {
    final bool isSelected = _selected == text;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          title: Text(text, style: const TextStyle(fontSize: 16)),
          onTap: () {
            setState(() => _selected = text);
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
        title: const Text('Quyền nhắc đến'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          _tile(
            icon: Icons.alternate_email_outlined,
            title: "Ai có thể nhắc đến bạn",
            subtitle: _selected,
            onTap: _showMentionSheet,
          ),
        ],
      ),
    );
  }
}
