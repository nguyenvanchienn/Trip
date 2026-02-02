// ignore: unused_import
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/mail/pages/ChatPage.dart';
import 'ArchivedChatsPage.dart';

class RecentChats extends StatefulWidget {
  const RecentChats({super.key});

  @override
  State<RecentChats> createState() => _RecentChatsState();
}

class _RecentChatsState extends State<RecentChats> {
  // Quản lý trạng thái của từng cuộc trò chuyện
  final Set<int> _pinnedChats = {};
  final Set<int> _mutedChats = {};
  final Map<int, int> _unreadCounts = {};
  final Map<int, DateTime> _lastMessageTime = {}; // Thời gian tin nhắn mới nhất

  @override
  void initState() {
    super.initState();
    // Khởi tạo unread counts và thời gian tin nhắn
    for (int i = 0; i < 10; i++) {
      _unreadCounts[i] = i % 4;
      // Mô phỏng thời gian tin nhắn cuối (cách nhau vài phút)
      _lastMessageTime[i] = DateTime.now().subtract(Duration(minutes: i * 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mô phỏng cho từng conversation với tên khác nhau
    final List<String> names = [
      'Alex Johnson',
      'Maria Garcia',
      'David Chen',
      'Sarah Wilson',
      'Mike Brown',
      'Emily Davis',
      'James Miller',
      'Lisa Anderson',
      'Tom Martinez',
      'Anna White',
    ];

    final List<String> messages = [
      'Hey, how are you doing?',
      'Let\'s meet tomorrow!',
      'Thanks for your help',
      'See you later 👋',
      'Can you send me the file?',
      'Great work on the project!',
      'What time is the meeting?',
      'Happy birthday! 🎉',
      'I\'ll be there in 5 minutes',
      'Did you see my message?',
    ];

    final List<String> times = [
      '10:30 AM',
      '9:15 AM',
      'Yesterday',
      '2:45 PM',
      '11:20 AM',
      'Monday',
      '3:00 PM',
      '8:30 AM',
      '1:15 PM',
      '4:50 PM',
    ];

    final List<Map<String, dynamic>> conversations = List.generate(10, (i) {
      final unreadCount = i % 4; // 0, 1, 2, 3
      final isMyLastMessage = i % 3 == 0; // Tin nhắn cuối của mình
      final isRead = i % 2 == 0; // Người kia đã đọc hay chưa

      return {
        'name': names[i],
        'avatar': 'asset/images/OIP.jpg',
        'lastMessage': messages[i],
        'time': times[i],
        'unreadCount': unreadCount,
        'isOnline': i % 2 == 0,
        'lastActiveMinutes': (i + 1) * 3,
        'isMyLastMessage': isMyLastMessage,
        'isRead': isRead,
      };
    });

    // Sắp xếp: ghim lên đầu, sau đó theo thời gian tin nhắn mới nhất
    final sortedIndices = List.generate(conversations.length, (i) => i);
    sortedIndices.sort((a, b) {
      final aPinned = _pinnedChats.contains(a);
      final bPinned = _pinnedChats.contains(b);

      // Ghim lên đầu
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      // Nếu cùng trạng thái ghim, sắp xếp theo thời gian tin nhắn mới nhất
      final aTime = _lastMessageTime[a] ?? DateTime(2000);
      final bTime = _lastMessageTime[b] ?? DateTime(2000);
      return bTime.compareTo(aTime); // Mới hơn lên trên
    });

    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i in sortedIndices)
            _buildChatItem(context, conversations[i], i),
        ],
      ),
    );
  }

  void _showChatOptions(
    BuildContext context,
    String name,
    int index,
    Map<String, dynamic> chat,
  ) {
    final isPinned = _pinnedChats.contains(index);
    final isMuted = _mutedChats.contains(index);
    final rootContext = context; // Lưu context gốc

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Color(0xFF0084FF),
                ),
                title: Text(
                  isPinned ? 'Bỏ ghim cuộc trò chuyện' : 'Ghim cuộc trò chuyện',
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    if (isPinned) {
                      _pinnedChats.remove(index);
                    } else {
                      _pinnedChats.add(index);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isPinned
                            ? 'Đã bỏ ghim cuộc trò chuyện với $name'
                            : 'Đã ghim cuộc trò chuyện với $name',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.archive_outlined, color: Color(0xFF0084FF)),
                title: Text('Lưu trữ'),
                onTap: () {
                  Navigator.pop(context);
                  // Thêm vào danh sách lưu trữ
                  ArchivedChatsPage.addArchivedChat(chat);
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Text('Đã lưu trữ cuộc trò chuyện với $name'),
                      action: SnackBarAction(
                        label: 'Xem',
                        onPressed: () {
                          Navigator.push(
                            rootContext,
                            MaterialPageRoute(
                              builder: (_) => ArchivedChatsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isMuted
                      ? Icons.notifications
                      : Icons.notifications_off_outlined,
                  color: Color(0xFF0084FF),
                ),
                title: Text(isMuted ? 'Bật thông báo' : 'Tắt thông báo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    if (isMuted) {
                      _mutedChats.remove(index);
                    } else {
                      _mutedChats.add(index);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isMuted
                            ? 'Đã bật thông báo cho $name'
                            : 'Đã tắt thông báo cho $name',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.mark_chat_unread_outlined,
                  color: Color(0xFF0084FF),
                ),
                title: Text('Đánh dấu chưa đọc'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _unreadCounts[index] = (_unreadCounts[index] ?? 0) + 1;
                    _lastMessageTime[index] =
                        DateTime.now(); // Cập nhật thời gian - tin nhắn mới đến
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã đánh dấu chưa đọc')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Xóa cuộc trò chuyện',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, name, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String name, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Xóa cuộc trò chuyện'),
          content: Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện với $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _pinnedChats.remove(index);
                  _mutedChats.remove(index);
                  _unreadCounts.remove(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa cuộc trò chuyện với $name')),
                );
              },
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    Map<String, dynamic> chat,
    int index,
  ) {
    final unreadCount = _unreadCounts[index] ?? 0;
    final isMyLastMessage = chat['isMyLastMessage'] as bool;
    final isRead = chat['isRead'] as bool;
    final isOnline = chat['isOnline'] as bool;
    final lastActiveMinutes = chat['lastActiveMinutes'] as int;
    final isPinned = _pinnedChats.contains(index);
    final isMuted = _mutedChats.contains(index);

    return Dismissible(
      key: Key('chat_item_$index'),
      direction: DismissDirection.endToStart,
      dismissThresholds: {DismissDirection.endToStart: 0.4},
      confirmDismiss: (direction) async {
        // Hiển thị menu tùy chọn khi swipe
        _showChatOptions(context, chat['name'], index, chat);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade300, Color(0xFF0084FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_horiz, color: Colors.white, size: 32),
                SizedBox(height: 4),
                Text(
                  'Tùy chọn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      child: Container(
        color: isPinned ? Colors.grey.shade50 : Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: InkWell(
            onTap: () {
              // Đánh dấu đã đọc và cập nhật thời gian khi mở chat (giả lập gửi tin nhắn)
              setState(() {
                _unreadCounts[index] = 0;
                _lastMessageTime[index] = DateTime.now(); // Tin nhắn mới nhất
              });
              // Sử dụng root Navigator để ẩn bottom navigation bar
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (context) => ChatPage(user: chat)),
              );
            },
            onLongPress: () {
              _showChatOptions(context, chat['name'], index, chat);
            },
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.asset(
                        chat['avatar'],
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Icon ghim
                    if (isPinned)
                      Positioned(
                        top: -5,
                        left: -5,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFF0084FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.push_pin,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Hiển thị trạng thái online hoặc thời gian offline
                    isOnline
                        ? Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          )
                        : Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '${lastActiveMinutes}m',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF113953),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isMuted)
                            Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: Icon(
                                Icons.notifications_off,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              chat['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF113953),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        unreadCount >= 2 && !isMyLastMessage
                            ? '$unreadCount tin nhắn mới'
                            : chat['lastMessage'],
                        style: TextStyle(
                          fontSize: 16,
                          color: unreadCount > 0 && !isMyLastMessage
                              ? Colors.black87
                              : Colors.black54,
                          fontWeight: unreadCount > 0 && !isMyLastMessage
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat['time'],
                      style: TextStyle(
                        fontSize: 15,
                        color: unreadCount > 0 && !isMyLastMessage
                            ? Color(0xFF0084FF)
                            : Colors.black54,
                        fontWeight: unreadCount > 0 && !isMyLastMessage
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Dấu chấm xanh (tin nhắn từ người khác chưa đọc)
                    if (unreadCount > 0 && !isMyLastMessage)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(0xFF0084FF),
                          shape: BoxShape.circle,
                        ),
                      )
                    // Avatar người xem (tin nhắn của mình đã được xem)
                    else if (isMyLastMessage && isRead)
                      ClipOval(
                        child: Image.asset(
                          chat['avatar'],
                          width: 18,
                          height: 18,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      SizedBox(height: 18), // Giữ khoảng trống để căn chỉnh
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
