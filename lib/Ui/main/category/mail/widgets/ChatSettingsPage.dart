import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/Profile.dart';
import 'package:tourn/Ui/main/category/mail/widgets/SearchMessagesPage.dart';
import 'package:tourn/Ui/main/category/mail/widgets/MediaGalleryPage.dart';
import 'package:tourn/Ui/main/category/mail/widgets/ChatCustomizationPage.dart';

class ChatSettingsPage extends StatefulWidget {
  final String name;
  final String? avatar;
  final bool isOnline;

  const ChatSettingsPage({
    super.key,
    required this.name,
    this.avatar,
    this.isOnline = false,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  bool _notificationsEnabled = true;
  bool _isBlocked = false; // Trạng thái chặn người dùng
  Color _chatColor = Color(0xFF113953);
  String _chatEmoji = '👍';
  String? _backgroundImage;

  void _openCustomization() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatCustomizationPage(
          chatName: widget.name,
          currentColor: _chatColor,
          currentEmoji: _chatEmoji,
          currentBackgroundImage: _backgroundImage,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _chatColor = result['color'] ?? _chatColor;
        _chatEmoji = result['emoji'] ?? _chatEmoji;
        _backgroundImage = result['backgroundImage'];
      });
    }
  }

  void _showNicknameDialog() {
    final TextEditingController nicknameController = TextEditingController(
      text: widget.name,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thay đổi biệt danh'),
        content: TextField(
          controller: nicknameController,
          decoration: InputDecoration(
            hintText: 'Nhập biệt danh mới',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã đổi biệt danh thành "${nicknameController.text}"',
                  ),
                ),
              );
            },
            child: Text('Lưu', style: TextStyle(color: Color(0xFF113953))),
          ),
        ],
      ),
    );
  }

  void _showDeleteHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa lịch sử trò chuyện'),
        content: Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa lịch sử trò chuyện')),
              );
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    if (_isBlocked) {
      // Nếu đã chặn, hiện dialog bỏ chặn
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Bỏ chặn người dùng'),
          content: Text('Bạn có muốn bỏ chặn ${widget.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isBlocked = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã bỏ chặn ${widget.name}')),
                );
              },
              child: Text('Bỏ chặn', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    } else {
      // Nếu chưa chặn, hiện dialog chặn
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Chặn người dùng'),
          content: Text(
            'Bạn có chắc chắn muốn chặn ${widget.name}?\n\nKhi chặn:\n• Bạn sẽ không nhận được tin nhắn từ người này\n• Họ sẽ không thể nhìn thấy khi bạn online\n• Cuộc trò chuyện vẫn được lưu',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isBlocked = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã chặn ${widget.name}'),
                    action: SnackBarAction(
                      label: 'Hoàn tác',
                      onPressed: () {
                        setState(() {
                          _isBlocked = false;
                        });
                      },
                    ),
                  ),
                );
              },
              child: Text('Chặn', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF113953),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, {'emoji': _chatEmoji, 'color': _chatColor});
          },
        ),
        title: Text(
          'Cài đặt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Avatar và tên - cùng background màu trắng với menu
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF113953).withOpacity(0.2),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Color(0xFF113953).withOpacity(0.1),
                        backgroundImage: widget.avatar != null
                            ? NetworkImage(widget.avatar!)
                            : null,
                        child: widget.avatar == null
                            ? Icon(
                                Icons.person,
                                size: 55,
                                color: Color(0xFF113953).withOpacity(0.5),
                              )
                            : null,
                      ),
                    ),
                    if (widget.isOnline)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 15),
                Text(
                  widget.name,
                  style: TextStyle(
                    color: Color(0xFF113953),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  widget.isOnline ? 'Đang hoạt động' : 'Không hoạt động',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Danh sách các tùy chọn
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF113953).withOpacity(0.1),
              child: Icon(Icons.person, color: Color(0xFF113953)),
            ),
            title: Text('Xem trang cá nhân'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Mở profile với bottom navigation bar
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => profile(
                    name: widget.name,
                    avatar: widget.avatar,
                    isOnline: widget.isOnline,
                    showBottomNav: true, // Hiển thị bottom nav bar
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF113953).withOpacity(0.1),
              child: Icon(Icons.search, color: Color(0xFF113953)),
            ),
            title: Text('Tìm kiếm tin nhắn'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchMessagesPage(chatName: widget.name),
                ),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF113953).withOpacity(0.1),
              child: Icon(Icons.edit, color: Color(0xFF113953)),
            ),
            title: Text('Thay đổi biệt danh'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _showNicknameDialog,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF113953).withOpacity(0.1),
              child: Icon(Icons.color_lens, color: Color(0xFF113953)),
            ),
            title: Text('Đổi màu sắc chat'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _chatColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: _openCustomization,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF113953).withOpacity(0.1),
              child: Icon(Icons.emoji_emotions, color: Color(0xFF113953)),
            ),
            title: Text('Đổi biểu tượng cảm xúc'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_chatEmoji, style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: _openCustomization,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF113953).withOpacity(0.1),
              child: Icon(Icons.photo_library, color: Color(0xFF113953)),
            ),
            title: Text('Xem ảnh & video'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaGalleryPage(chatName: widget.name),
                ),
              );
            },
          ),
          SwitchListTile(
            secondary: CircleAvatar(
              backgroundColor: Color(0xFF113953).withOpacity(0.1),
              child: Icon(
                _notificationsEnabled
                    ? Icons.notifications
                    : Icons.notifications_off,
                color: Color(0xFF113953),
              ),
            ),
            title: Text('Thông báo'),
            subtitle: Text(_notificationsEnabled ? 'Đang bật' : 'Đã tắt'),
            value: _notificationsEnabled,
            activeThumbColor: Color(0xFF113953),
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Đã bật thông báo' : 'Đã tắt thông báo',
                  ),
                ),
              );
            },
          ),
          Divider(height: 30, thickness: 1, color: Colors.grey.shade200),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(Icons.delete_outline, color: Colors.red),
            ),
            title: Text(
              'Xóa lịch sử trò chuyện',
              style: TextStyle(color: Colors.red),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.red),
            onTap: _showDeleteHistoryDialog,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _isBlocked
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Icon(
                _isBlocked ? Icons.check_circle : Icons.block,
                color: _isBlocked ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              _isBlocked ? 'Bỏ chặn người dùng' : 'Chặn người dùng',
              style: TextStyle(color: _isBlocked ? Colors.green : Colors.red),
            ),
            subtitle: _isBlocked
                ? Text(
                    'Đã chặn - Nhấn để bỏ chặn',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  )
                : null,
            trailing: Icon(
              Icons.chevron_right,
              color: _isBlocked ? Colors.green : Colors.red,
            ),
            onTap: _showBlockUserDialog,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(Icons.report, color: Colors.red),
            ),
            title: Text('Báo cáo', style: TextStyle(color: Colors.red)),
            trailing: Icon(Icons.chevron_right, color: Colors.red),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Đã gửi báo cáo')));
            },
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
