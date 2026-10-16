import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // Thư viện để chọn ảnh từ thư viện hoặc chụp ảnh mới
import 'dart:io'; // Để làm việc với File
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';

// Gemini API configuration
const String _geminiApiKey = 'AIzaSyBOsbV2denSv5Z9tBvo3JIdn7ua4KeMSQw';
// Use stable model gemini-2.0-flash (2.5-flash and 1.5-flash are deprecated)
const String _geminiApiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

// System prompt for Trip AI
const String _systemPrompt = '''
Bạn là Trip AI - trợ lý thông minh của ứng dụng Trip, một ứng dụng du lịch và mạng xã hội.

Về ứng dụng Trip:
- Trip là ứng dụng giúp người dùng lên kế hoạch du lịch, khám phá địa điểm mới
- Người dùng có thể chia sẻ hình ảnh, trải nghiệm du lịch của mình
- Ứng dụng có tính năng nhắn tin, theo dõi bạn bè, xem bản đồ
- Người dùng có thể check-in địa điểm, đánh giá và review
- Có trang cá nhân với thông tin, ảnh đại diện, tiểu sử
- Hỗ trợ quản lý email, mật khẩu, cài đặt tài khoản
- Trip là một ứng dụng được phát triển bởi người Việt Nam, do Nguyễn Văn Chiến phát triển. Ứng dụng được thiết kế hướng tới thị trường Việt Nam và khu vực Đông Nam Á, với mục tiêu mang đến trải nghiệm thân thiện, dễ sử dụng và phù hợp với thói quen của người dùng trong khu vực. Nhờ giao diện trực quan cùng cách bố trí chức năng hợp lý, Trip giúp người dùng thao tác nhanh chóng và thuận tiện trong quá trình sử dụng.

Hướng dẫn trả lời:
1. Luôn trả lời bằng tiếng Việt trừ khi người dùng hỏi bằng ngôn ngữ khác
2. Ưu tiên giúp đỡ về các tính năng trong ứng dụng Trip
3. Có thể trả lời các câu hỏi chung về du lịch, địa điểm, văn hóa
4. Khi được hỏi về tính năng chưa có, hãy gợi ý các tính năng hiện có
5. Giữ câu trả lời ngắn gọn, thân thiện và hữu ích
6. Sử dụng emoji phù hợp để tạo sự thân thiện
7. Nếu không chắc chắn, hãy hỏi thêm thông tin từ người dùng
8. có thể truy cập vào thông tin về các địa điểm du lịch, khách sạn, nhà hàng, phương tiện di chuyển để hỗ trợ người dùng lên kế hoạch du lịch
9. có thể hướng dẫn người dùng cách sử dụng các tính năng của ứng dụng Trip, như cách tạo bài viết, chia sẻ hình ảnh, nhắn tin với bạn bè, khám phá bản đồ, lưu địa điểm yêu thích, cài đặt tài khoản, v.v.
10. có thể trả lời các câu hỏi chung về du lịch, như gợi ý địa điểm du lịch, kinh nghiệm du lịch, văn hóa địa phương, v.v.
11. Nếu người dùng hỏi về tính năng chưa có trong ứng dụng, hãy trả lời một cách tích cực và gợi ý các tính năng hiện có mà có thể giúp ích cho họ.
12. Luôn giữ câu trả lời ngắn gọn, thân thiện và hữu ích, đồng thời sử dụng emoji phù hợp để tạo sự thân thiện và gần gũi với người dùng.
13. Nếu người dùng hỏi về ứng dụng bạn có thể thao tác các chức năng trong ứng dụng như tạo bài viết, chia sẻ hình ảnh, nhắn tin với bạn bè, khám phá bản đồ, lưu địa điểm yêu thích, cài đặt tài khoản, v.v. để hỗ trợ người dùng sử dụng ứng dụng một cách hiệu quả nhất.
14. Bạn có quyền truy cập vào các chức năng của ứng dụng Trip để hỗ trợ người dùng, nhưng hãy đảm bảo rằng bạn luôn hỏi ý kiến người dùng trước khi thực hiện bất kỳ hành động nào thay mặt họ.
15. Khi người dùng yêu cầu tạo cái gì đó liên quan đến ứng dụng Trip, hãy hỏi thêm chi tiết về yêu cầu của họ để đảm bảo rằng bạn hiểu đúng và có thể thực hiện chính xác theo mong muốn của họ.


Các tính năng chính:
- Trang chủ: Xem bài viết, tin tức du lịch
- Tin nhắn: Chat với bạn bè, cuộc gọi video
- Bản đồ: Khám phá địa điểm xung quanh
- Yêu thích: Lưu địa điểm, thông báo
- Menu: Cài đặt, trang cá nhân, quyền riêng tư
''';

const String _aiUserId = 'trip_ai';
const String _aiUserName = 'Trip AI';

Future<String> _callGeminiAPI(
  String userMessage,
  List<ChatMessage> history,
) async {
  // Try a list of candidate endpoints in order until one returns a 200
  final endpoints = [
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent',
  ];

  // Retry configuration
  const maxRetries = 3;
  const retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  // Build conversation payload once
  final List<Map<String, dynamic>> contents = [];
  contents.add({
    'role': 'user',
    'parts': [
      {'text': _systemPrompt},
    ],
  });
  contents.add({
    'role': 'model',
    'parts': [
      {
        'text':
            'Tôi hiểu rồi. Tôi là Trip AI, trợ lý của ứng dụng Trip. Tôi sẽ hỗ trợ người dùng về du lịch và các tính năng của ứng dụng.',
      },
    ],
  });
  final recentHistory = history.length > 6
      ? history.sublist(history.length - 6)
      : history;
  for (final msg in recentHistory) {
    if (msg.imagePath == null) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text},
        ],
      });
    }
  }
  contents.add({
    'role': 'user',
    'parts': [
      {'text': userMessage},
    ],
  });

  // Retry logic with exponential backoff
  for (int retry = 0; retry <= maxRetries; retry++) {
    if (retry > 0) {
      // Wait before retrying
      debugPrint(
        'Retrying after ${retryDelays[retry - 1].inSeconds} seconds...',
      );
      await Future.delayed(retryDelays[retry - 1]);
    }

    for (final endpoint in endpoints) {
      try {
        final response = await http.post(
          Uri.parse('$endpoint?key=$_geminiApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            },
            'safetySettings': [
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_HATE_SPEECH',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
              {
                'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? 'Xin lỗi, tôi không thể tạo phản hồi.';
            }
          }
          final promptFeedback = data['promptFeedback'];
          if (promptFeedback != null) {
            debugPrint('Gemini blocked: $promptFeedback');
            return 'Xin lỗi, tin nhắn không thể xử lý. Vui lòng thử nội dung khác.';
          }
          return 'Xin lỗi, không có phản hồi từ AI.';
        } else if (response.statusCode == 404) {
          // model not available, try next endpoint
          debugPrint('Gemini 404 at $endpoint');
          continue;
        } else if (response.statusCode == 429) {
          debugPrint('Gemini API Rate Limit ($endpoint): ${response.body}');
          // Try next endpoint instead of returning immediately
          continue;
        } else if (response.statusCode == 400) {
          debugPrint('Gemini API Bad Request ($endpoint): ${response.body}');
          return 'Tin nhắn không hợp lệ. Vui lòng thử lại với nội dung khác.';
        } else if (response.statusCode == 403) {
          debugPrint('Gemini API Forbidden ($endpoint): ${response.body}');
          return 'API key không hợp lệ hoặc không có quyền truy cập AI.';
        } else {
          debugPrint(
            'Gemini API Error ($endpoint): ${response.statusCode} - ${response.body}',
          );
          return 'Lỗi ${response.statusCode}. Vui lòng thử lại sau. 🔄';
        }
      } catch (e) {
        debugPrint('Exception calling $endpoint: $e');
        // continue to next endpoint
      }
    }
    // All endpoints failed for this retry, continue to next retry
  }

  return 'Hệ thống đang bận, vui lòng thử lại sau vài giây. ⏳';
}

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
  final bool fullScreen;
  final bool combineHistory;

  const AIChatBottomSheet({
    super.key,
    this.fullScreen = false,
    this.combineHistory = false,
  });

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Image preview before sending
  XFile? _pendingImage;

  // Activity status
  DateTime _lastActiveTime = DateTime.now();
  bool _isOnline = true;

  // Track which message's time is shown
  int? _selectedMessageIndex;
  bool _initialScrollDone = false;

  // Quản lý nhiều đoạn chat
  List<ChatConversation> _conversations = [];
  String? _currentConversationId;

  List<ChatMessage> get _messages {
    final conv = _conversations.firstWhere(
      (c) => c.id == _currentConversationId,
      orElse: () => ChatConversation(
        id: '',
        title: '',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return conv.messages;
  }

  List<ChatMessage> get _visibleMessages {
    if (!widget.combineHistory) {
      return _messages;
    }
    final all = <ChatMessage>[];
    for (final c in _conversations) {
      all.addAll(c.messages);
    }
    all.removeWhere(
      (m) => !m.isUser && m.text.trim().startsWith('Xin chào! Tôi là Trip AI'),
    );
    all.sort((a, b) => a.time.compareTo(b.time));
    return all;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
    _loadActivityStatus();
    _updateActivityStatus(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateActivityStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _updateActivityStatus(false);
    }
  }

  Future<void> _loadActivityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getString('ai_last_active_time');
    if (lastActive != null) {
      _lastActiveTime = DateTime.tryParse(lastActive) ?? DateTime.now();
    }
  }

  Future<void> _updateActivityStatus(bool isOnline) async {
    _isOnline = isOnline;
    if (!isOnline) {
      _lastActiveTime = DateTime.now();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ai_last_active_time',
      DateTime.now().toIso8601String(),
    );
    if (mounted) setState(() {});
  }

  String _getActivityStatusText() {
    if (_isOnline) {
      return 'Đang hoạt động';
    }
    final diff = DateTime.now().difference(_lastActiveTime);
    if (diff.inMinutes < 1) return 'Vừa mới hoạt động';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('ai_conversations');
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        _conversations = jsonList
            .map((j) => ChatConversation.fromJson(j))
            .toList();
        // Keep conversations even when they only contain AI messages.
      } catch (e) {
        _conversations = [];
      }
    }

    if (_conversations.isEmpty) {
      _createNewConversation();
    } else {
      // Mở đoạn chat gần nhất
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _currentConversationId = _conversations.first.id;
    }

    if (!widget.combineHistory) {
      _createNewConversation();
    }

    if (mounted) setState(() {});
    if (!_initialScrollDone) {
      _initialScrollDone = true;
    }
    _scrollToBottom();
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString('ai_conversations', data);
  }

  void _createNewConversation({bool seedGreeting = true}) {
    // Xoá đoạn chat rỗng trước khi tạo mới
    _cleanupEmptyConversations();

    final now = DateTime.now();
    final newConv = ChatConversation(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'Đoạn chat mới',
      messages: seedGreeting
          ? [
              ChatMessage(
                text:
                    'Xin chào! Tôi là Trip AI - trợ lý thông minh của ứng dụng Trip. 🌍✈️\n\nTôi có thể giúp bạn:\n• Lên kế hoạch du lịch\n• Tìm hiểu địa điểm\n• Hướng dẫn sử dụng ứng dụng\n• Trả lời các câu hỏi về du lịch\n\nHãy hỏi tôi bất cứ điều gì!',
                isUser: false,
                time: now,
              ),
            ]
          : [],
      createdAt: now,
      updatedAt: now,
    );
    _conversations.insert(0, newConv);
    _currentConversationId = newConv.id;
    _saveConversations();
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _deleteConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    if (_currentConversationId == id) {
      if (_conversations.isEmpty) {
        _createNewConversation();
      } else {
        _currentConversationId = _conversations.first.id;
      }
    }
    _saveConversations();
    if (mounted) setState(() {});
  }

  void _renameConversation(String id, String newTitle) {
    final conv = _conversations.firstWhere((c) => c.id == id);
    conv.title = newTitle;
    _saveConversations();
    if (mounted) setState(() {});
  }

  void _switchConversation(String id) {
    // Xoá đoạn chat hiện tại nếu rỗng trước khi chuyển
    _cleanupEmptyConversations();
    _currentConversationId = id;
    if (mounted) setState(() {});
    _scrollToBottom();
    Navigator.pop(context); // Đóng menu
  }

  void _cleanupEmptyConversations() {
    // Xoá tất cả đoạn chat không có tin nhắn user (trừ đoạn đang chọn)
    _conversations.removeWhere(
      (c) => c.id != _currentConversationId && !c.messages.any((m) => m.isUser),
    );
  }

  ChatConversation? get _currentConversation {
    try {
      return _conversations.firstWhere((c) => c.id == _currentConversationId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;
    if (_currentConversation == null) {
      _createNewConversation();
    }
    if (_currentConversation == null) return;

    final userMessage = _messageController.text.trim();
    final userMsg = ChatMessage(
      text: userMessage,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _currentConversation!.messages.add(userMsg);
      _isLoading = true;
    });

    // Cập nhật tiêu đề đoạn chat nếu là tin nhắn đầu tiên của user
    if (_currentConversation!.messages.where((m) => m.isUser).length == 1) {
      _currentConversation!.title = userMessage.length > 30
          ? '${userMessage.substring(0, 30)}...'
          : userMessage;
    }
    _currentConversation!.updatedAt = DateTime.now();

    _messageController.clear();
    _scrollToBottom();

    final conversationId = await _syncAiConversation(userMessage);

    // Gọi Gemini API
    final aiResponse = await _callGeminiAPI(userMessage, _messages);

    if (conversationId != null) {
      await _syncAiResponse(conversationId, aiResponse);
    }

    if (mounted && _currentConversation != null) {
      setState(() {
        _currentConversation!.messages.add(
          ChatMessage(text: aiResponse, isUser: false, time: DateTime.now()),
        );
        _isLoading = false;
      });
      _currentConversation!.updatedAt = DateTime.now();
      _saveConversations();
      _scrollToBottom();
    }
  }

  Future<String?> _syncAiConversation(String userMessage) async {
    final msgRepo = context.read<MessageRepository>();
    final currentUserId = msgRepo.currentUserId;
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để tạo chat AI.')),
        );
      }
      return null;
    }

    try {
      final userRepo = context.read<UserRepository>();
      final currentUser = await userRepo.getCurrentUser();
      final conversation = await msgRepo.getOrCreatePrivateConversation(
        otherUserId: _aiUserId,
        otherUserName: _aiUserName,
        otherUserPhoto: null,
        currentUserName: currentUser?.displayName,
        currentUserPhoto: currentUser?.photoUrl,
      );
      if (conversation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Khong tao duoc cuoc tro chuyen Trip AI.'),
            ),
          );
        }
        return null;
      }

      // Seed a greeting message once for new conversations.
      if (conversation.lastMessageAt == null &&
          (conversation.lastMessage == null ||
              conversation.lastMessage!.isEmpty)) {
        await msgRepo.sendMessage(
          conversationId: conversation.id,
          content:
              'Xin chào! Tôi là Trip AI - trợ lý thông minh của ứng dụng Trip. 🌍✈️\n\nTôi có thể giúp bạn:\n• Lên kế hoạch du lịch\n• Tìm hiểu địa điểm\n• Hướng dẫn sử dụng ứng dụng\n• Trả lời các câu hỏi về du lịch\n\nHãy hỏi tôi bất cứ điều gì!',
          senderName: _aiUserName,
          senderIdOverride: _aiUserId,
        );
      }

      await msgRepo.sendMessage(
        conversationId: conversation.id,
        content: userMessage,
        senderName: currentUser?.displayName ?? '',
      );
      return conversation.id;
    } catch (e) {
      debugPrint('Failed to sync Trip AI conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Loi tao chat Trip AI: $e')));
      }
      return null;
    }
  }

  Future<void> _syncAiResponse(String conversationId, String response) async {
    if (response.trim().isEmpty) return;
    try {
      final msgRepo = context.read<MessageRepository>();
      await msgRepo.sendMessage(
        conversationId: conversationId,
        content: response,
        senderName: _aiUserName,
        senderIdOverride: _aiUserId,
      );
    } catch (e) {
      debugPrint('Failed to sync Trip AI response: $e');
    }
  }

  void _scrollToBottom() {
    void doJump() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }

    void doAnimate() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      doJump();
      Future.delayed(const Duration(milliseconds: 100), doJump);
      Future.delayed(const Duration(milliseconds: 220), doAnimate);
    });
  }

  void _showConversationMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Lịch sử đoạn chat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _createNewConversation();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Mới'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Danh sách đoạn chat
            Expanded(
              child: Builder(
                builder: (context) {
                  // Lọc chỉ hiển thị các đoạn chat có tin nhắn user hoặc đang được chọn
                  final visibleConversations = _conversations
                      .where(
                        (c) =>
                            c.messages.any((m) => m.isUser) ||
                            c.id == _currentConversationId,
                      )
                      .toList();

                  if (visibleConversations.isEmpty) {
                    return const Center(child: Text('Chưa có đoạn chat nào'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: visibleConversations.length,
                    itemBuilder: (context, index) {
                      final conv = visibleConversations[index];
                      final isSelected = conv.id == _currentConversationId;
                      final msgCount = conv.messages
                          .where((m) => m.isUser)
                          .length;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? const Color(0xFF113953)
                              : Colors.grey[200],
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          msgCount == 0 ? 'Đoạn chat mới' : conv.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '$msgCount tin nhắn • ${_formatDate(conv.updatedAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        selectedTileColor: const Color(
                          0xFF113953,
                        ).withOpacity(0.1),
                        onTap: () => _switchConversation(conv.id),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            if (value == 'rename') {
                              Navigator.pop(context);
                              _showRenameDialog(conv);
                            } else if (value == 'delete') {
                              Navigator.pop(context);
                              _showDeleteDialog(conv);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Đổi tên'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xoá',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(ChatConversation conv) {
    final controller = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên đoạn chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _renameConversation(conv.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF113953),
            ),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ChatConversation conv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá đoạn chat'),
        content: Text(
          'Bạn có chắc muốn xoá "${conv.title}"?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteConversation(conv.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                this.context,
              ).showSnackBar(const SnackBar(content: Text('Đã xoá đoạn chat')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xoá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${date.day}/${date.month}/${date.year}';
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
          _pendingImage = picked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể chọn ảnh')));
    }
  }

  void _cancelPendingImage() {
    setState(() {
      _pendingImage = null;
    });
  }

  void _sendImageWithMessage() async {
    if (_pendingImage == null) return;
    if (_currentConversation == null) {
      _createNewConversation();
    }
    if (_currentConversation == null) return;

    final imagePath = _pendingImage!.path;
    final userText = _messageController.text.trim();
    final messageText = userText.isNotEmpty ? userText : 'Đã gửi ảnh';

    setState(() {
      _currentConversation!.messages.add(
        ChatMessage(
          text: messageText,
          isUser: true,
          time: DateTime.now(),
          imagePath: imagePath,
        ),
      );
      _currentConversation!.updatedAt = DateTime.now();
      _pendingImage = null;
      _isLoading = true;
    });

    _messageController.clear();
    _saveConversations();
    _scrollToBottom();

    // Phản hồi từ AI - hiện tại chưa hỗ trợ phân tích ảnh
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && _currentConversation != null) {
      setState(() {
        _currentConversation!.messages.add(
          ChatMessage(
            text:
                'Tôi đã nhận được ảnh của bạn! 📸\n\nHiện tại tính năng phân tích ảnh đang được phát triển. Bạn có thể mô tả ảnh hoặc hỏi tôi điều gì đó về nó!',
            isUser: false,
            time: DateTime.now(),
          ),
        );
        _currentConversation!.updatedAt = DateTime.now();
        _isLoading = false;
      });
      _saveConversations();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (!widget.fullScreen)
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
              if (widget.combineHistory)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              // Menu button - hiển thị danh sách đoạn chat
              if (!widget.combineHistory)
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF113953)),
                  onPressed: _showConversationMenu,
                  tooltip: 'Lịch sử chat',
                ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.combineHistory
                          ? 'Đang hoạt động'
                          : (_currentConversation?.title ??
                                'Trợ lý thông minh'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Tạo đoạn chat mới
              if (!widget.combineHistory)
                IconButton(
                  icon: const Icon(
                    Icons.add_comment_outlined,
                    color: Color(0xFF113953),
                  ),
                  onPressed: () {
                    _createNewConversation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã tạo đoạn chat mới'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: 'Đoạn chat mới',
                ),
              if (!widget.combineHistory)
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _visibleMessages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _visibleMessages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(_visibleMessages[index]);
              },
            ),
          ),
        ),
        // Image preview before sending
        if (_pendingImage != null) _buildImagePreview(),
        _buildMessageInput(),
      ],
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: content),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: content,
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
                padding: const EdgeInsets.all(4),
                child: Image.asset("asset/icon/logo.png", fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF113953),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Đang suy nghĩ...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_pendingImage!.path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: _cancelPendingImage,
                  tooltip: 'Huỷ',
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh đã chọn',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhấn gửi để chia sẻ ảnh này',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
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
                        decoration: InputDecoration(
                          hintText: _pendingImage != null
                              ? 'Thêm tin nhắn (tuỳ chọn)...'
                              : 'Nhập tin nhắn...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _pendingImage != null
                            ? _sendImageWithMessage()
                            : _sendMessage(),
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
                icon: Icon(_pendingImage != null ? Icons.send : Icons.send),
                color: Colors.white,
                onPressed: _pendingImage != null
                    ? _sendImageWithMessage
                    : _sendMessage,
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
  final bool isDeletedForMe;
  final bool isDeletedForAll;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
    this.isDeletedForMe = false,
    this.isDeletedForAll = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? time,
    String? imagePath,
    bool? isDeletedForMe,
    bool? isDeletedForAll,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      time: time ?? this.time,
      imagePath: imagePath ?? this.imagePath,
      isDeletedForMe: isDeletedForMe ?? this.isDeletedForMe,
      isDeletedForAll: isDeletedForAll ?? this.isDeletedForAll,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'time': time.toIso8601String(),
    'imagePath': imagePath,
    'isDeletedForMe': isDeletedForMe,
    'isDeletedForAll': isDeletedForAll,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
    imagePath: json['imagePath'],
    isDeletedForMe: json['isDeletedForMe'] ?? false,
    isDeletedForAll: json['isDeletedForAll'] ?? false,
  );
}

class ChatConversation {
  String id;
  String title;
  List<ChatMessage> messages;
  DateTime createdAt;
  DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Đoạn chat mới',
        messages:
            (json['messages'] as List?)
                ?.map((m) => ChatMessage.fromJson(m))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}
