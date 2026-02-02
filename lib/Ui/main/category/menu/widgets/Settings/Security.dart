import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Security/change_password.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Security/two_factor_page.dart';

class Security extends StatefulWidget {
  const Security({super.key});

  @override
  State<Security> createState() => _SecurityState();
}

class _SecurityState extends State<Security> {
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
            icon: Icons.lock_outline,
            title: 'Đổi mật khẩu',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChangePasswork())),
          ),

          // Account section
          _tile(
            icon: Icons.person_outline,
            title: 'Xác thực 2 yếu tố',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TwoFactorPage())),
          ),
        ],
      ),
    );
  }
}
