import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/settings/accountmanagement/badge.dart';
import 'package:tourn/Ui/main/category/menu/widgets/settings/accountmanagement/birthday.dart';
import 'package:tourn/Ui/main/category/menu/widgets/settings/accountmanagement/email.dart';
import 'package:tourn/Ui/main/category/menu/widgets/settings/accountmanagement/name.dart';
import 'package:tourn/Ui/main/category/menu/widgets/settings/accountmanagement/tennguoidung.dart';
import 'package:tourn/Ui/main/category/menu/widgets/settings/accountmanagement/phone_number.dart';

class Quanlytaikhoan extends StatefulWidget {
  const Quanlytaikhoan({super.key});

  @override
  State<Quanlytaikhoan> createState() => _QuanlytaikhoanState();
}

class _QuanlytaikhoanState extends State<Quanlytaikhoan> {
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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Quản lý tài khoản'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _tile(
            icon: Icons.person_outline,
            title: 'Tên ',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const NamePage())),
          ),

          // Account section
          _tile(
            icon: Icons.person_outline,
            title: 'Tên người dùng',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TenNguoiDungPage())),
          ),
          _tile(
            icon: Icons.person_outline,
            title: 'Ngày sinh',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BirthdayPage())),
          ),
          _tile(
            icon: Icons.email_outlined,
            title: 'Email',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EmailListPage())),
          ),
          _tile(
            icon: Icons.phone_outlined,
            title: 'Số điện thoại',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PhoneListPage())),
          ),
          _tile(
            icon: Icons.badge_outlined,
            title: 'Giấy tờ tuỳ thân',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BadgePage())),
          ),

          const SizedBox(height: 8),

          // Privacy & safety

          // Content & activity
        ],
      ),
    );
  }
}
