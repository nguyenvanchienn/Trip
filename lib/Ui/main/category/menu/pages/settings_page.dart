import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Security.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Security/two_factor_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/account_management.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final bool _pushNotifications = true;
  final bool _allowComments = true;
  final bool _recommendation = true;
  final bool _darkMode = false;
  final bool _activityStatus = true; // Trạng thái hoạt động

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mở Quyền riêng tư...')),
              );
            },
          ),
          _tile(
            icon: Icons.comment_bank_outlined,
            title: 'Bình luận',
            subtitle: 'Cho phép/khóa bình luận',
            trailing: Switch(value: _allowComments, onChanged: (v) {}),
            onTap: () {},
          ),

          const SizedBox(height: 8),

          // Content & activity
          _sectionHeader('Nội dung & hoạt động'),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Quyền riêng tư của tài khoản',
            onTap: () => _openPage(
              'Quyền riêng tư của tài khoản',
              'Cài đặt quyền riêng tư.',
            ),
          ),
          _tile(
            icon: Icons.repeat,
            title: 'Follow & tương tác',
            onTap: () => _openPage('Follow & tương tác', 'Cài đặt tương tác.'),
          ),
          _tile(
            icon: Icons.recommend_outlined,
            title: 'Gợi ý nội dung',
            trailing: Switch(value: _recommendation, onChanged: (v) {}),
            onTap: () {},
          ),
          _tile(icon: Icons.block_outlined, title: 'Chặn', onTap: () {}),
          _tile(
            icon: Icons.history_outlined,
            title: 'Hoạt động của bạn',
            onTap: () {},
          ),
          _tile(
            icon: Icons.visibility_outlined,
            title: 'Trạng thái hoạt động',
            trailing: Switch(value: _activityStatus, onChanged: (v) {}),
            onTap: () {},
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thông tin đăng nhập đã lưu')),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mở Trung tâm trợ giúp...')),
              );
            },
          ),
          _tile(
            icon: Icons.feedback_outlined,
            title: 'Gửi phản hồi',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mở Gửi phản hồi...')),
              );
            },
          ),
          _tile(
            icon: Icons.info_outline,
            title: 'Giới thiệu',
            subtitle: 'Phiên bản ứng dụng',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Mở Giới thiệu...')));
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
