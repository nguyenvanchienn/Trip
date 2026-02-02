import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/mail/widgets/ArchivedChatsPage.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _isDarkMode = false;
  bool _isActiveStatus = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header với nút đóng
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFF113953), size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),

            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 10),
                children: [
                  // Kho lưu trữ
                  _buildMenuItem(
                    icon: Icons.archive_outlined,
                    title: 'Kho lưu trữ',
                    badge: ArchivedChatsPage.archivedChats.isNotEmpty
                        ? '${ArchivedChatsPage.archivedChats.length}'
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArchivedChatsPage(),
                        ),
                      );
                    },
                  ),

                  // Yêu cầu tin nhắn
                  _buildMenuItem(
                    icon: Icons.mark_chat_unread_outlined,
                    title: 'Yêu cầu tin nhắn',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Không có yêu cầu tin nhắn mới'),
                        ),
                      );
                    },
                  ),

                  // Marketplace
                  Divider(indent: 20, endIndent: 20),

                  // Trạng thái hoạt động
                  _buildSwitchItem(
                    icon: Icons.circle,
                    iconColor: _isActiveStatus ? Colors.green : Colors.grey,
                    title: 'Trạng thái hoạt động',
                    value: _isActiveStatus,
                    onChanged: (value) {
                      setState(() {
                        _isActiveStatus = value;
                      });
                    },
                  ),

                  // Chế độ tối
                  _buildSwitchItem(
                    icon: Icons.dark_mode_outlined,
                    iconColor: Color(0xFF113953),
                    title: 'Chế độ tối',
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                    },
                  ),

                  Divider(indent: 20, endIndent: 20),

                  // Bong bóng chat

                  // Quyền riêng tư & an toàn
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Quyền riêng tư & an toàn',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Thông báo & âm thanh
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo & âm thanh',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Tùy chọn tin nhắn
                  _buildMenuItem(
                    icon: Icons.message_outlined,
                    title: 'Tùy chọn tin nhắn',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Ảnh & file phương tiện
                  _buildMenuItem(
                    icon: Icons.photo_library_outlined,
                    title: 'Ảnh & file phương tiện',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Trợ năng
                  _buildMenuItem(
                    icon: Icons.accessibility_new_outlined,
                    title: 'Trợ năng',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  Divider(indent: 20, endIndent: 20),

                  // Báo cáo sự cố kỹ thuật
                  _buildMenuItem(
                    icon: Icons.bug_report_outlined,
                    title: 'Báo cáo sự cố kỹ thuật',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Trợ giúp
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Trợ giúp',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Pháp lý & chính sách
                  _buildMenuItem(
                    icon: Icons.policy_outlined,
                    title: 'Pháp lý & chính sách',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(15),
              child: Text(
                'TRIP © 2026',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Color(0xFF113953), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF113953),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            )
          : null,
      trailing: badge != null
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF0084FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF113953),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Color(0xFF0084FF),
      ),
    );
  }
}
