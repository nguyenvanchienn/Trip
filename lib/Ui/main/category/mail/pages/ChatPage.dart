import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/mail/widgets/VoiceCallPage.dart';
import 'package:tourn/Ui/main/category/mail/widgets/VideoCallPage.dart';
import 'package:tourn/Ui/main/category/mail/widgets/ChatSettingsPage.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ChatPage({super.key, this.user});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController =
      TextEditingController(); // Điều khiển ô nhập tin nhắn
  final ScrollController _scrollController =
      ScrollController(); // Điều khiển cuộn danh sách tin nhắn
  final List<Map<String, dynamic>> _messages = []; // Danh sách tin nhắn
  int? _selectedMessageIndex; // Chỉ mục tin nhắn được chọn
  bool _isLoadingMore = false; // Trạng thái đang load tin nhắn cũ
  int _messageCounter = 0; // Đếm số tin nhắn để tạo tin nhắn mẫu
  bool _hasText = false; // Kiểm tra ô nhập có text hay không
  String _currentEmoji = '👍'; // Emoji hiện tại từ customization

  @override
  void initState() {
    super.initState();
    // Tin nhắn mẫu ban đầu
    _messages.add({
      'text': 'xin chào bạn!',
      'isMe': false,
      'time': DateTime.now(),
      'status': 'seen',
    });
    _messages.add({
      'text': 'xin chào bạn!',
      'isMe': true,
      'time': DateTime.now(),
      'status': 'seen',
    });
    _messageCounter = 2;

    // Lắng nghe sự kiện cuộn
    _scrollController.addListener(_onScroll);

    // Lắng nghe thay đổi text trong ô nhập
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Mô phỏng load từ server
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        // Thêm tin nhắn cũ vào đầu danh sách
        _messages.insertAll(0, [
          {
            'text': 'Tin nhắn cũ ${_messageCounter + 1}',
            'isMe': false,
            'time': DateTime.now().subtract(
              Duration(hours: _messageCounter + 1),
            ),
            'status': 'seen',
          },
          {
            'text': 'Tin nhắn cũ ${_messageCounter + 2}',
            'isMe': true,
            'time': DateTime.now().subtract(Duration(hours: _messageCounter)),
            'status': 'seen',
          },
        ]);
        _messageCounter += 2;
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageIndex = _messages.length;
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
        'time': DateTime.now(),
        'status': 'sending', // Đang gửi
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // Mô phỏng quá trình gửi tin nhắn
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages[messageIndex]['status'] = 'sent'; // Đã gửi
        });
      }
    });

    // Mô phỏng tin nhắn đã xem
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages[messageIndex]['status'] = 'seen'; // Đã xem
        });
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // Cuộn xuống cuối
          duration: const Duration(milliseconds: 300), //
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Mở modal chọn file/ảnh/vị trí khi nhấn nút '+'
  void _onAttachPressed() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Ảnh & Video'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: tích hợp chọn ảnh
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file),
                title: Text('Tệp'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.place),
                title: Text('Vị trí'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  bool _isOnlyEmoji(String text) {
    // Kiểm tra xem text có phải chỉ là emoji không
    final emojiRegex = RegExp(
      r'^[\u{1F300}-\u{1F9FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]+$',
      unicode: true,
    );
    return text.trim().isNotEmpty && emojiRegex.hasMatch(text.trim());
  }

  bool _shouldShowTimestamp(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    final currentTime = currentMessage['time'] as DateTime;
    final previousTime = previousMessage['time'] as DateTime;

    // Nếu cách nhau > 60 phút thì hiển thị timestamp
    return currentTime.difference(previousTime).inMinutes > 60;
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Hôm nay - chỉ hiện giờ
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Hôm qua
      return 'Hôm qua ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // Trong tuần
      final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return '${weekdays[time.weekday % 7]} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // Lâu hơn - hiện ngày tháng
      return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.user != null
        ? (widget.user!['isOnline'] as bool? ?? true)
        : true;
    final int lastActive = widget.user != null
        ? (widget.user!['lastActiveMinutes'] as int? ?? 0)
        : 0;
    final String name = widget.user != null
        ? (widget.user!['name'] as String? ?? 'Programmer')
        : 'Programmer';
    final String? imageUrl = widget.user != null
        ? (widget.user!['imageUrl'] as String?)
        : null;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: EdgeInsets.only(top: 5),
          child: AppBar(
            leadingWidth: 30,
            title: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ChatSettingsPage(name: name);
                            },
                          ),
                        );
                        // Cập nhật emoji nếu có thay đổi
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _currentEmoji = result['emoji'] ?? _currentEmoji;
                          });
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Image.asset(
                          "asset/images/OIP.jpg",
                          width: 45,
                          height: 45,
                        ),
                      ),
                    ),
                    if (isOnline) // show green dot
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Color(0xFF113953),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 2),
                        child: Text(
                          isOnline
                              ? "Đang hoạt động"
                              : 'Hoạt động $lastActive phút trước',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF113953),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 0),
                child: IconButton(
                  icon: Icon(Icons.call, color: Color(0xFF113953), size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VoiceCallPage(name: name, avatar: imageUrl),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 0),
                child: IconButton(
                  icon: Icon(
                    Icons.video_call,
                    color: Color(0xFF113953),
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoCallPage(name: name, avatar: imageUrl),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;
                final text = message['text'] as String;
                final status = message['status'] as String?;
                final time = message['time'] as DateTime;
                final showTimestamp = _shouldShowTimestamp(index);

                // Kiểm tra xem có phải tin nhắn chỉ là emoji không
                final isOnlyEmoji = _isOnlyEmoji(text);

                return Column(
                  children: [
                    // Hiển thị timestamp nếu cách nhau lâu
                    if (showTimestamp)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _formatTimestamp(time),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    // Tin nhắn
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMessageIndex = _selectedMessageIndex == index
                              ? null
                              : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Avatar người nhận (bên trái)
                            if (!isMe) ...[
                              Opacity(
                                opacity: _selectedMessageIndex == index
                                    ? 0.5
                                    : 1.0,
                                child: ClipOval(
                                  child: Image.asset(
                                    "asset/images/OIP.jpg",
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Giờ gửi bên trái tin nhắn nhận (khi tap)
                            if (!isMe && _selectedMessageIndex == index) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  bottom: 8,
                                ),
                                child: Text(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.65,
                                ),
                                child: Opacity(
                                  opacity: _selectedMessageIndex == index
                                      ? 0.5
                                      : 1.0,
                                  child: isOnlyEmoji
                                      ? Text(
                                          text,
                                          style: TextStyle(fontSize: 64),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? const Color(0xFF113953)
                                                : const Color(0xFFE1E1E2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            text,
                                            softWrap: true,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            // Giờ gửi bên phải tin nhắn gửi (khi tap)
                            if (isMe && _selectedMessageIndex == index) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  bottom: 8,
                                ),
                                child: Text(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                            // Trạng thái hoặc avatar người xem (bên phải) - chỉ hiện khi KHÔNG được chọn
                            if (isMe &&
                                status != null &&
                                _selectedMessageIndex != index) ...[
                              const SizedBox(width: 4),
                              status == 'seen'
                                  ? ClipOval(
                                      child: Image.asset(
                                        "asset/images/OIP.jpg",
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      status == 'sending'
                                          ? Icons.access_time
                                          : Icons.check,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Color(0xFFE0E0E0), width: 1),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Color(0xFF113953), size: 22),
                onPressed: _onAttachPressed,
              ),
            ),

            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0), width: 1),
              ),
              child: IconButton(
                icon: Icon(Icons.image, color: Color(0xFF113953), size: 25),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0), width: 1),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.keyboard_voice_sharp,
                  color: Color(0xFF113953),
                  size: 25,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Aa',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _hasText
                ? Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF113953),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send),
                      color: Colors.white,
                      onPressed: _sendMessage,
                    ),
                  )
                : InkWell(
                    onTap: () {
                      // Gửi emoji nhanh
                      final messageIndex = _messages.length;
                      setState(() {
                        _messages.add({
                          'text': _currentEmoji,
                          'isMe': true,
                          'time': DateTime.now(),
                          'status': 'sending',
                        });
                      });

                      _scrollToBottom();

                      // Mô phỏng quá trình gửi
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _messages[messageIndex]['status'] = 'sent';
                          });
                        }
                      });

                      // Mô phỏng tin nhắn đã xem
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _messages[messageIndex]['status'] = 'seen';
                          });
                        }
                      });
                    },
                    onLongPress: () async {
                      // Giữ lâu để mở settings thay đổi emoji
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatSettingsPage(name: 'Programmer'),
                        ),
                      );
                      // Cập nhật emoji nếu có thay đổi
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _currentEmoji = result['emoji'] ?? _currentEmoji;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: Text(
                        _currentEmoji,
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
