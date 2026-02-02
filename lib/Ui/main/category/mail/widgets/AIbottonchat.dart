import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Thư viện để chọn ảnh từ thư viện hoặc chụp ảnh mới
import 'dart:io'; // Để làm việc với File

void buildBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 1, // Chiều cao ban đầu (90%)
      minChildSize: 0.7, // Chiều cao tối thiểu khi kéo xuống (50%)
      maxChildSize: 1, // Chiều cao tối đa khi kéo lên (95%)
      builder: (context, scrollController) => const AIChatBottomSheet(),
    ),
  );
}

class AIChatBottomSheet extends StatefulWidget {
  const AIChatBottomSheet({super.key});

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Tin nhắn chào mừng từ AI
    _messages.add(
      ChatMessage(
        text:
            'Xin chào! Tôi là trợ lý AI của TRIP. Tôi có thể giúp gì cho bạn hôm nay?',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, time: DateTime.now()),
      );
    });

    _messageController.clear();
    _scrollToBottom();

    // Mô phỏng phản hồi từ AI sau 1 giây
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _generateAIResponse(userMessage),
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  String _generateAIResponse(String userMessage) {
    // Đây là phản hồi mẫu, bạn có thể tích hợp API AI thực tế
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('chào') ||
        lowerMessage.contains('hello') ||
        lowerMessage.contains('hi')) {
      return 'Chào bạn! Rất vui được trò chuyện với bạn. 😊';
    } else if (lowerMessage.contains('du lịch') ||
        lowerMessage.contains('travel')) {
      return 'Tôi có thể giúp bạn lên kế hoạch du lịch! Bạn muốn đi đâu?';
    } else if (lowerMessage.contains('giúp') || lowerMessage.contains('help')) {
      return 'Tôi sẵn sàng hỗ trợ bạn! Hãy cho tôi biết bạn cần giúp gì nhé.';
    } else if (lowerMessage.contains('cảm ơn') ||
        lowerMessage.contains('thank')) {
      return 'Không có gì! Tôi luôn sẵn sàng giúp đỡ bạn. 💙';
    } else {
      return 'Tôi đã hiểu câu hỏi của bạn. Để trả lời chính xác hơn, bạn có thể cung cấp thêm chi tiết không?';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF113953)),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF113953),
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: Color(0xFF113953),
              ),
              title: const Text('Chọn file'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Đã gửi ảnh',
              isUser: true,
              time: DateTime.now(),
              imagePath: picked.path,
            ),
          );
        });
        _scrollToBottom();

        // Phản hồi từ AI
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _messages.add(
              ChatMessage(
                text:
                    'Tôi đã nhận được ảnh của bạn! Đây là một bức ảnh đẹp. 📸',
                isUser: false,
                time: DateTime.now(),
              ),
            );
          });
          _scrollToBottom();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể chọn ảnh')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar để kéo
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Header với avatar AI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF113953), Color(0xFF1E5A7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 5,
                        left: 4,
                        right: 6,
                        bottom: 5,
                      ),
                      child: Image.asset(
                        "asset/icon/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRIP AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Trợ lý thông minh',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Danh sách tin nhắn
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF113953), Color(0xFF1E5A7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                    left: 4,
                    right: 5,
                    bottom: 4,
                  ),
                  child: Image.asset(
                    "asset/icon/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF113953) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị ảnh nếu có
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.time),
                    style: TextStyle(
                      color: message.isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _showAttachmentOptions,
                      color: Colors.grey[600],
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn...',
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
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF113953), Color(0xFF1E5A7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: const Icon(Icons.send),
                color: Colors.white,
                onPressed: _sendMessage,
                tooltip: 'Gửi',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
  });
}
