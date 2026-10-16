import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/binhluan.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/chedotaikhoan.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/danhsachdafollow.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/ganthe.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/hanche.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/nhacden.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/taikhoanbichan.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/taive.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/quyenriengtuvaantoan/tinnhan.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';

class Quyenriengtuvaantoan extends StatefulWidget {
  const Quyenriengtuvaantoan({super.key});

  @override
  State<Quyenriengtuvaantoan> createState() => _QuyenriengtuvaantoanState();
}

class _QuyenriengtuvaantoanState extends State<Quyenriengtuvaantoan> {
  final FirebaseAccountService _accountService = FirebaseAccountService();
  bool _activityStatus = true;
  bool _privateAccount = false;
  bool _loading = true;
  bool _isBusinessMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _accountService.getAccountSettings();
      if (!mounted) return;
      setState(() {
        _privateAccount = settings.isPrivate;
        _activityStatus = settings.showActivityStatus;
        _isBusinessMode = settings.isBusinessAccount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải cài đặt: ${e.toString()}')),
      );
    }
  }

  Future<void> _updatePrivateAccount(bool value) async {
    setState(() => _privateAccount = value);
    try {
      await _accountService.updatePrivateAccount(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _privateAccount = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateActivityStatus(bool value) async {
    setState(() => _activityStatus = value);
    try {
      await _accountService.updateActivityStatus(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _activityStatus = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: ${e.toString()}')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Quản lý tài khoản'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),

                _tile(
                  icon: Icons.switch_account_outlined,
                  title: 'Chế độ tài khoản',
                  subtitle: _isBusinessMode
                      ? 'Tài khoản doanh nghiệp'
                      : 'Tài khoản cá nhân',
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            Chedotaikhoan(initialIsBusiness: _isBusinessMode),
                      ),
                    );
                    if (!mounted || result == null) return;
                    setState(() {
                      _isBusinessMode = result;
                    });
                  },
                ),
                // Privacy
                _tile(
                  icon: Icons.lock_outline,
                  title: 'Tài khoản riêng tư',
                  subtitle: _privateAccount
                      ? 'Chỉ người theo dõi đã được bạn duyệt mới xem nội dung của bạn'
                      : 'Mọi người đều có thể xem bài viết và thông tin của bạn',
                  trailing: Switch(
                    value: _privateAccount,
                    onChanged: _updatePrivateAccount,
                  ),
                ),

                _tile(
                  icon: Icons.circle_outlined,
                  title: 'Trạng thái hoạt động',
                  subtitle: _activityStatus
                      ? 'Bạn bè có thể thấy khi bạn đang online'
                      : 'Bạn bè sẽ không thấy trạng thái hoạt động của bạn',
                  trailing: Switch(
                    value: _activityStatus,
                    onChanged: _updateActivityStatus,
                  ),
                ),

                _sectionHeader('Tương tác'),

                _tile(
                  icon: Icons.comment_outlined, // bình luận
                  title: 'Bình luận',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const Binhluan())),
                ),

                _tile(
                  icon: Icons.alternate_email_outlined, // nhắc đến
                  title: 'Nhắc đến',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const Nhacden())),
                ),

                _tile(
                  icon: Icons.chat_bubble_outline, // tin nhắn
                  title: 'Tin nhắn',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const Tinnhan())),
                ),

                _tile(
                  icon: Icons.download_outlined, // tải về
                  title: 'Tải về',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const Taive())),
                ),
                _tile(
                  icon: Icons.local_offer_outlined, // gắn thẻ
                  title: 'Gắn thẻ',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const Ganthe())),
                ),

                _tile(
                  icon: Icons.group_outlined, // đã follow
                  title: 'Danh sách đã follow',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Danhsachdafollow()),
                  ),
                ),
                _tile(
                  icon: Icons.person_remove_outlined, // icon Hạn chế chuẩn
                  title: 'Tài khoản bị hạn chế',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const HanChePage())),
                ),
                _tile(
                  icon: Icons.block_outlined, // chặn
                  title: 'Tài khoản bị chặn',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Taikhoanbichan()),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
    );
  }
}
