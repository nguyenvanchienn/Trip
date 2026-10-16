import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/conversation_model.dart';
import 'package:tourn/models/message_model.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/FirebaseRecentChats.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/MessageBubble.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageRequestsPage extends StatefulWidget {
  const MessageRequestsPage({super.key});

  @override
  State<MessageRequestsPage> createState() => _MessageRequestsPageState();
}

class _MessageRequestsPageState extends State<MessageRequestsPage> {
  // Track friends (mutual following) to filter message requests
  Set<String> _friendIds = {};

  bool _ensureSignedIn() {
    if (FirebaseAuth.instance.currentUser != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final messageRepository = context.read<MessageRepository>();
    final currentUserId = messageRepository.currentUserId;
    if (currentUserId == null) return;

    final userRepository = context.read<UserRepository>();
    final currentUser = await userRepository.getUserById(currentUserId);
    if (currentUser == null) return;

    // Friends = intersection of followers and following
    final followers = currentUser.followers.toSet();
    final following = currentUser.following.toSet();
    setState(() {
      _friendIds = followers.intersection(following);
    });
  }

  bool _isMessageRequest(ConversationModel conversation, String currentUserId) {
    // Only private conversations
    if (conversation.type != ConversationType.private) return false;

    // Skip if current user created the conversation
    if (conversation.createdBy == currentUserId) return false;

    // Skip if current user has already accepted
    if (conversation.hasAccepted(currentUserId)) return false;

    // Get the other participant
    final otherUserId = conversation.getOtherParticipantId(currentUserId);

    // Skip if they are friends
    if (_friendIds.contains(otherUserId)) return false;

    // This is a message request
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final messageRepository = context.read<MessageRepository>();
    final currentUserId = messageRepository.currentUserId ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF113953)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yêu cầu tin nhắn',
          style: TextStyle(
            color: Color(0xFF113953),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: messageRepository.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không thể tải yêu cầu tin nhắn',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data!;
          final messageRequests = conversations
              .where((c) => _isMessageRequest(c, currentUserId))
              .toList();

          if (messageRequests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_chat_unread_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có yêu cầu tin nhắn',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tin nhắn từ người lạ sẽ xuất hiện ở đây',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: messageRequests.length,
            itemBuilder: (context, index) {
              final conversation = messageRequests[index];
              return _MessageRequestItem(
                conversation: conversation,
                currentUserId: currentUserId,
                onAccept: () => _acceptRequest(conversation),
                onDelete: () => _deleteRequest(conversation),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _acceptRequest(ConversationModel conversation) async {
    final messageRepository = context.read<MessageRepository>();
    await messageRepository.acceptConversation(conversation.id);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã chấp nhận tin nhắn')));
    }
  }

  Future<void> _deleteRequest(ConversationModel conversation) async {
    final messageRepository = context.read<MessageRepository>();
    await messageRepository.rejectConversation(conversation.id);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa yêu cầu tin nhắn')));
    }
  }
}

class _MessageRequestItem extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onDelete;

  const _MessageRequestItem({
    required this.conversation,
    required this.currentUserId,
    required this.onAccept,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = conversation.getDisplayName(currentUserId);
    final displayPhoto = conversation.getDisplayPhoto(currentUserId);
    final otherUserId = conversation.getOtherParticipantId(currentUserId);

    return StreamBuilder<UserModel?>(
      stream: context.read<UserRepository>().streamUser(otherUserId),
      builder: (context, userSnapshot) {
        final otherUser = userSnapshot.data;

        return InkWell(
          onTap: () {
            // Navigate to message request chat view
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _MessageRequestChatPage(
                  conversation: conversation,
                  currentUserId: currentUserId,
                  displayName: displayName,
                  displayPhoto: displayPhoto,
                  otherUser: otherUser,
                  onAccept: onAccept,
                  onDelete: onDelete,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: displayPhoto != null
                      ? getImageProvider(displayPhoto)
                      : const AssetImage('asset/images/OIP.jpg')
                            as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF113953),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage ?? 'Tin nhắn mới',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Chat page for message request - shows profile info and Accept/Delete/Block buttons
class _MessageRequestChatPage extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final String displayName;
  final String? displayPhoto;
  final UserModel? otherUser;
  final VoidCallback onAccept;
  final VoidCallback onDelete;

  const _MessageRequestChatPage({
    required this.conversation,
    required this.currentUserId,
    required this.displayName,
    required this.displayPhoto,
    required this.otherUser,
    required this.onAccept,
    required this.onDelete,
  });

  @override
  State<_MessageRequestChatPage> createState() =>
      _MessageRequestChatPageState();
}

class _MessageRequestChatPageState extends State<_MessageRequestChatPage> {
  final ScrollController _scrollController = ScrollController();

  bool _ensureSignedIn() {
    if (FirebaseAuth.instance.currentUser != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần đăng nhập để thực hiện thao tác này')),
    );
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUserId = widget.conversation.getOtherParticipantId(
      widget.currentUserId,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF113953)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.displayPhoto != null
                      ? getImageProvider(widget.displayPhoto!)
                      : const AssetImage('asset/images/OIP.jpg')
                            as ImageProvider,
                ),
                // Online indicator
                if (widget.otherUser != null &&
                    isUserOnline(
                      widget.otherUser!.isOnline,
                      widget.otherUser!.lastSeen,
                    ))
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.displayName,
                  style: const TextStyle(
                    color: Color(0xFF113953),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (widget.otherUser != null)
                  Text(
                    formatLastSeen(
                      widget.otherUser!.lastSeen,
                      widget.otherUser!.isOnline,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isUserOnline(
                            widget.otherUser!.isOnline,
                            widget.otherUser!.lastSeen,
                          )
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFF113953)),
            onPressed: () {
              // Call functionality - disabled for message requests
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chấp nhận yêu cầu tin nhắn để có thể gọi điện',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFF113953)),
            onPressed: () {
              // Video call functionality - disabled for message requests
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chấp nhận yêu cầu tin nhắn để có thể gọi video',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages section
          Expanded(
            child: StreamBuilder(
              stream: context.read<MessageRepository>().getMessages(
                widget.conversation.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể tải tin nhắn\nVui lòng kiểm tra kết nối mạng',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile header section
                    _buildProfileHeader(otherUserId),
                    const SizedBox(height: 20),
                    // Messages with timestamp separators
                    ..._buildMessageList(messages.toList()),
                  ],
                );
              },
            ),
          ),

          // Bottom section with info and buttons
          _buildBottomSection(otherUserId),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String otherUserId) {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[300],
          backgroundImage: widget.displayPhoto != null
              ? getImageProvider(widget.displayPhoto!)
              : const AssetImage('asset/images/OIP.jpg') as ImageProvider,
        ),
        const SizedBox(height: 12),
        // Name
        Text(
          widget.displayName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF113953),
          ),
        ),
        const SizedBox(height: 4),
        // Not friends text
        const Text(
          'Các bạn không phải là bạn bè trên Trip',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        // Action buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Follow button
            ElevatedButton.icon(
              onPressed: () async {
                if (!_ensureSignedIn()) return;
                // Follow user
                await FirebaseUserService().followUser(otherUserId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã theo dõi ${widget.displayName}'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Theo dõi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // View profile button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(userId: otherUserId),
                  ),
                );
              },
              icon: const Icon(Icons.person, size: 16),
              label: const Text('Xem trang cá nhân'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Request message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Yêu cầu trò chuyện đã được gửi tới ${widget.displayName}.\nVui lòng đợi ${widget.displayName} chấp nhận.',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        // Timestamp
        Text(
          _formatDate(widget.conversation.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// Build message list with timestamp separators and MessageBubble widgets
  List<Widget> _buildMessageList(List<MessageModel> messages) {
    // Reverse messages to show oldest first
    final reversedMessages = messages.reversed.toList();
    final widgets = <Widget>[];
    final otherUserId = widget.conversation.getOtherParticipantId(
      widget.currentUserId,
    );

    for (int i = 0; i < reversedMessages.length; i++) {
      final message = reversedMessages[i];
      final prevMessage = i > 0 ? reversedMessages[i - 1] : null;
      final nextMessage = i < reversedMessages.length - 1
          ? reversedMessages[i + 1]
          : null;

      // Show timestamp separator if 20+ minutes gap
      if (shouldShowTimestamp(prevMessage, message)) {
        widgets.add(
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                formatMessageTime(message.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ),
        );
      }

      final isMe = message.senderId == widget.currentUserId;
      // Show avatar for last message in a series from same sender
      final showAvatar =
          nextMessage == null ||
          nextMessage.senderId != message.senderId ||
          shouldShowTimestamp(message, nextMessage);

      // Check if this is the last message and has been seen
      final isLastMessage = i == reversedMessages.length - 1;
      final hasBeenSeen =
          isMe && isLastMessage && message.readBy.contains(otherUserId);

      widgets.add(
        MessageBubble(
          message: message,
          isMe: isMe,
          senderPhotoUrl: isMe ? null : widget.displayPhoto,
          currentUserId: widget.currentUserId,
          showAvatar: showAvatar,
        ),
      );

      // Add seen indicator after the last message if it was sent by me and read
      if (hasBeenSeen) {
        widgets.add(
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, top: 4),
              child: CircleAvatar(
                radius: 8,
                backgroundImage: widget.displayPhoto != null
                    ? getImageProvider(widget.displayPhoto!)
                    : const AssetImage('asset/images/OIP.jpg') as ImageProvider,
              ),
            ),
          ),
        );
      }
      // Add sent indicator for last message if sent by me but not yet read
      else if (isMe && isLastMessage && !hasBeenSeen) {
        widgets.add(
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check, size: 12, color: Colors.grey),
                  Text(
                    ' Đã gửi',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildBottomSection(String otherUserId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Info text
          Text(
            'Nếu bạn chấp nhận, ${widget.displayName} sẽ có thể gọi cho bạn, '
            'biết các thông tin như Trạng thái hoạt động của bạn và thời điểm bạn đọc tin nhắn.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Link to settings
          GestureDetector(
            onTap: () {
              // Navigate to privacy settings
            },
            child: const Text(
              'Chọn ai có thể nhắn tin cho bạn',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              // Block button
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Chặn người này?'),
                        content: Text(
                          'Bạn có chắc muốn chặn ${widget.displayName}? '
                          'Họ sẽ không thể nhắn tin hoặc gọi cho bạn nữa.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Chặn'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      // Block user
                      await FirebaseUserService().blockUser(otherUserId);
                      widget.onDelete();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Chặn'),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa yêu cầu?'),
                        content: const Text(
                          'Yêu cầu tin nhắn này sẽ bị xóa vĩnh viễn.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      widget.onDelete();
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Xóa'),
                ),
              ),
              const SizedBox(width: 8),
              // Accept button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAccept();
                    Navigator.pop(context);
                    // Navigate to actual chat
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FirebaseChatPage(
                          conversationId: widget.conversation.id,
                          displayName: widget.displayName,
                          displayPhoto: widget.displayPhoto,
                          isGroup:
                              widget.conversation.type ==
                              ConversationType.group,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF113953),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Chấp nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'THG 1',
      'THG 2',
      'THG 3',
      'THG 4',
      'THG 5',
      'THG 6',
      'THG 7',
      'THG 8',
      'THG 9',
      'THG 10',
      'THG 11',
      'THG 12',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
