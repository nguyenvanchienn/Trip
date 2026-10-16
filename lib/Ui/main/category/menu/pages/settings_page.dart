import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/pages/Help.dart';

import 'package:tourn/Ui/main/category/menu/widgets/Settings/Guiphanhoi.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Security.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/account_management.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/hoatdongcuaban.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/introapp.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/thongtindangnhapdaluu.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final bool _pushNotifications = true;

  final bool _recommendation = true;
  final bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Keep UI in sync with global dark mode controller (if changed elsewhere)
  }

  Future<void> _loadSettings() async {
    // Lấy các giá trị lưu trong SharedPreferences (mỗi chức năng tách vào file riêng)
    setState(() {});
  }

  /// Lưu bool setting với rollback nếu lưu thất bại và hiển thị SnackBar xác nhận
  Future<void> _saveBoolSetting({
    required Future<void> Function(bool) saver,
    required void Function(bool) setter,
    required bool value,
    String? successMessage,
  }) async {
    // Optimistic update
    setter(value);
    try {
      await saver(value);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage ?? 'Đã lưu')));
    } catch (e) {
      // Revert on error
      setter(!value);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lưu thất bại: ${e.toString()}')));
    }
  }

  Widget _sectionHeader(String title) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).hintColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

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

  void _openPage(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text(body)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Cài đặt và quyền riêng tư'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Account section
          _sectionHeader('Tài khoản'),
          _tile(
            icon: Icons.person_outline,
            title: 'Quản lý tài khoản',
            subtitle: 'Tên người dùng, email, số điện thoại',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const Quanlytaikhoan()));
            },
          ),
          _tile(
            icon: Icons.lock_outline,
            title: 'Bảo mật',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const Security()));
            },
          ),

          const SizedBox(height: 8),

          // Privacy & safety
          _sectionHeader('Quyền riêng tư'),
          _tile(
            icon: Icons.shield_outlined,
            title: 'Quyền riêng tư & an toàn',
            subtitle: 'Ai có thể xem/ứng xử với bạn',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Quyenriengtuvaantoan()),
              );
            },
          ),

          const SizedBox(height: 8),

          // Content & activity
          _sectionHeader('Nội dung & hoạt động'),

          _tile(
            icon: Icons.recommend_outlined,
            title: 'Gợi ý nội dung',
            trailing: Switch(value: _recommendation, onChanged: (v) {}),
            onTap: () {},
          ),
          _tile(
            icon: Icons.history_outlined,
            title: 'Hoạt động của bạn',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const Hoatdongcuaban()));
            },
          ),

          const SizedBox(height: 8),

          // Notifications
          _sectionHeader('Thông báo'),
          _tile(
            icon: Icons.notifications_none,
            title: 'Thông báo đẩy',
            subtitle: 'Nhận thông báo mới',
            trailing: Switch(value: _pushNotifications, onChanged: (v) {}),
            onTap: () {},
          ),

          const SizedBox(height: 8),
          _tile(
            icon: Icons.vpn_key_outlined,
            title: 'Thông tin đăng nhập đã lưu',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Thongtindangnhapdaluu(),
                ),
              );
            },
          ),

          const SizedBox(height: 8),
          _sectionHeader('Tuỳ chọn và Hỗ trợ'),
          _tile(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối',

            trailing: Switch(value: _darkMode, onChanged: (v) {}),
            onTap: () {},
          ),
          _tile(
            icon: Icons.help_outline,
            title: 'Trung tâm trợ giúp',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Help()),
              );
            },
          ),
          _tile(
            icon: Icons.feedback_outlined,
            title: 'Gửi phản hồi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Guiphanhoi()),
              );
            },
          ),
          _tile(
            icon: Icons.info_outline,
            title: 'Giới thiệu',
            subtitle: 'Phiên bản ứng dụng',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const IntroAppPage()));
            },
          ),

          const SizedBox(height: 12),

          // Danger / Log out
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
