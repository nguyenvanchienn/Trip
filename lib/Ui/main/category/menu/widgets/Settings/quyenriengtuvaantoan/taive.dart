import 'package:flutter/material.dart';

class Taive extends StatefulWidget {
  const Taive({super.key});

  @override
  State<Taive> createState() => _TaiveState();
}

class _TaiveState extends State<Taive> {
  String _downloadPermission = 'Chỉ người theo dõi';
  final bool _allowDownload = true;

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
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        ListTile(
          leading: _leadingIcon(icon, color),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }

  // ===== BottomSheet =====
  void _showDownloadPermission() {
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
              'Ai có thể tải video của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),

            _option('Mọi người'),
            _option('Chỉ người theo dõi'),
            _option("Bạn bè"),
            _option('Chỉ mình tôi'),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _option(String text) {
    final bool isSelected = _downloadPermission == text;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          title: Text(text),
          onTap: () {
            setState(() => _downloadPermission = text);
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
        title: const Text('Tải video'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          _tile(
            icon: Icons.people_outline,
            title: 'Ai có thể tải video của bạn',
            subtitle: _downloadPermission,
            onTap: _allowDownload ? _showDownloadPermission : null,
          ),
        ],
      ),
    );
  }
}
