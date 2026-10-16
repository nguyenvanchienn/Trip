import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tourn/models/message_model.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/favorites/pages/Baiviet.dart';

/// Helper function to check if user is truly online
/// Returns true only if isOnline flag is true AND lastSeen is within 2 minutes
bool isUserOnline(bool isOnline, DateTime? lastSeen) {
  if (!isOnline) return false;
  if (lastSeen == null) return isOnline;

  final now = DateTime.now();
  final diff = now.difference(lastSeen);
  // Consider online only if lastSeen is within 2 minutes
  return diff.inMinutes < 2;
}

/// Helper function to format relative time (e.g., "5 phút trước", "Đang hoạt động")
String formatLastSeen(DateTime? lastSeen, bool isOnline) {
  // Use the helper to check true online status
  if (isUserOnline(isOnline, lastSeen)) return 'Đang hoạt động';
  if (lastSeen == null) return 'Không hoạt động';

  final now = DateTime.now();
  final diff = now.difference(lastSeen);

  if (diff.inMinutes < 1) {
    return 'Vừa mới truy cập';
  } else if (diff.inMinutes <= 59) {
    return 'Hoạt động ${diff.inMinutes} phút trước';
  } else if (diff.inHours < 24) {
    return 'Hoạt động ${diff.inHours} giờ trước';
  } else if (diff.inDays < 7) {
    return 'Hoạt động ${diff.inDays} ngày trước';
  } else {
    return 'Hoạt động ${DateFormat('dd/MM').format(lastSeen)}';
  }
}

/// Helper function to format message time
String formatMessageTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inDays == 0) {
    return DateFormat('HH:mm').format(time);
  } else if (diff.inDays == 1) {
    return 'Hôm qua ${DateFormat('HH:mm').format(time)}';
  } else if (diff.inDays < 7) {
    final weekday = _getVietnameseWeekday(time.weekday);
    return '$weekday ${DateFormat('HH:mm').format(time)}';
  } else {
    return DateFormat('dd/MM/yyyy HH:mm').format(time);
  }
}

String _getVietnameseWeekday(int weekday) {
  switch (weekday) {
    case 1:
      return 'Thứ Hai';
    case 2:
      return 'Thứ Ba';
    case 3:
      return 'Thứ Tư';
    case 4:
      return 'Thứ Năm';
    case 5:
      return 'Thứ Sáu';
    case 6:
      return 'Thứ Bảy';
    case 7:
      return 'Chủ Nhật';
    default:
      return '';
  }
}

/// Check if we should show timestamp separator (20+ minutes gap)
bool shouldShowTimestamp(
  MessageModel? previousMessage,
  MessageModel currentMessage,
) {
  if (previousMessage == null) return true;
  final diff = currentMessage.createdAt.difference(previousMessage.createdAt);
  return diff.inMinutes >= 20;
}

/// Message bubble widget with Messenger-like UI
class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderPhotoUrl;
  final String currentUserId;
  final bool showAvatar; // Show avatar for last message in a series
  final VoidCallback? onRecall;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final Function(MessageModel)? onForward;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderPhotoUrl,
    required this.currentUserId,
    this.showAvatar = true,
    this.onRecall,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onForward,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;

    // Don't show message if deleted for this user
    if (message.deletedFor.contains(widget.currentUserId)) {
      return const SizedBox.shrink();
    }

    // Handle recalled message
    if (message.isRecalled) {
      return _buildRecalledBubble(isMe);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showTime = !_showTime;
        });
      },
      onLongPress: () {
        _showMessageOptions(context);
      },
      child: Column(
        children: [
          // Message time (shown when tapped)
          if (_showTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                formatMessageTime(message.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 60 : 0, // Add padding for sender messages
              right: isMe ? 0 : 60, // Add padding for receiver messages
            ),
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for receiver (left side) - always show space, show image for last in series
                if (!isMe) ...[
                  if (widget.showAvatar)
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: widget.senderPhotoUrl != null
                          ? getImageProvider(widget.senderPhotoUrl!)
                          : const AssetImage('asset/images/OIP.jpg')
                                as ImageProvider,
                    )
                  else
                    const SizedBox(width: 28), // Space for avatar alignment
                  const SizedBox(width: 6),
                ],

                // Message bubble
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          (message.type == MessageType.image ||
                              message.type == MessageType.video)
                          ? 3
                          : 12,
                      vertical:
                          (message.type == MessageType.image ||
                              message.type == MessageType.video)
                          ? 3
                          : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF0084FF) // Messenger blue
                          : const Color(0xFFE4E6EB), // Light grey for receiver
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecalledBubble(bool isMe) {
    return Padding(
      padding: EdgeInsets.only(left: isMe ? 60 : 0, right: isMe ? 0 : 60),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[const SizedBox(width: 28), const SizedBox(width: 6)],
          Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Tin nhắn đã được thu hồi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
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

  Widget _buildMessageContent() {
    final message = widget.message;
    final isMe = widget.isMe;

    if (message.type == MessageType.image && message.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.mediaUrl!,
          width: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 200,
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 150,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 40),
            );
          },
        ),
      );
    } else if (message.type == MessageType.video && message.mediaUrl != null) {
      return Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
        ),
      );
    } else if (message.type == MessageType.audio && message.mediaUrl != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.audiotrack, color: isMe ? Colors.white : Colors.black54),
          const SizedBox(width: 8),
          Text(
            'Tin nhắn âm thanh',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        ],
      );
    } else if (message.type == MessageType.voiceCall) {
      // Voice call message
      final metadata = message.metadata;
      final answered = metadata?['answered'] ?? false;
      final isMissed = !answered;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMissed ? Icons.phone_missed : Icons.phone,
            color: isMissed
                ? Colors.red
                : (isMe ? Colors.white : Colors.black54),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isMissed
                  ? Colors.red
                  : (isMe ? Colors.white : Colors.black87),
              fontSize: 15,
            ),
          ),
        ],
      );
    } else if (message.type == MessageType.videoCall) {
      // Video call message
      final metadata = message.metadata;
      final answered = metadata?['answered'] ?? false;
      final isMissed = !answered;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMissed ? Icons.videocam_off : Icons.videocam,
            color: isMissed
                ? Colors.red
                : (isMe ? Colors.white : Colors.black54),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isMissed
                  ? Colors.red
                  : (isMe ? Colors.white : Colors.black87),
              fontSize: 15,
            ),
          ),
        ],
      );
    } else if (message.type == MessageType.sharedPost) {
      // Shared post message - clickable to view post
      return _buildSharedPostContent(message, isMe);
    } else {
      return Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      );
    }
  }

  /// Build shared post card (Facebook-style)
  Widget _buildSharedPostContent(MessageModel message, bool isMe) {
    final metadata = message.metadata ?? {};
    final postId = metadata['postId'] as String? ?? '';
    final authorName = metadata['authorName'] as String? ?? 'Người dùng';
    final authorPhotoUrl = metadata['authorPhotoUrl'] as String?;
    final content = metadata['content'] as String? ?? '';
    final mediaUrls =
        (metadata['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [];
    final backgroundColor = metadata['backgroundColor'] as String?;

    // Check if post has background color (text-only post)
    final hasBackgroundColor =
        backgroundColor != null &&
        backgroundColor != 'none' &&
        mediaUrls.isEmpty;

    return GestureDetector(
      onTap: () {
        // Navigate to post detail page with metadata as fallback
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Baiviet(
              postId: postId.isNotEmpty ? postId : null,
              post: metadata, // Pass metadata as fallback post data
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0074CC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isMe ? null : Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Post author header
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        authorPhotoUrl != null && authorPhotoUrl.isNotEmpty
                        ? getImageProvider(authorPhotoUrl)
                        : null,
                    backgroundColor: Colors.grey[400],
                    child: (authorPhotoUrl == null || authorPhotoUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Post content or background
            if (hasBackgroundColor)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _getGradient(backgroundColor),
                  color: _getGradient(backgroundColor) == null
                      ? _parseBackgroundColor(backgroundColor)
                      : null,
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )
            else if (mediaUrls.isNotEmpty)
              // Show first media image - handle both network URLs and asset paths
              _buildSharedPostImage(mediaUrls.first)
            else if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: isMe ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Tap to view indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.black.withOpacity(0.1)
                    : Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Nhấn để xem bài viết',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get gradient for background color
  LinearGradient? _getGradient(String? colorName) {
    switch (colorName) {
      case 'gradient_sunset':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_ocean':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_forest':
        return const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_night':
        return const LinearGradient(
          colors: [Color(0xFF232526), Color(0xFF414345)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }

  // Parse background color string to Color
  Color _parseBackgroundColor(String? backgroundColor) {
    if (backgroundColor == null) return Colors.transparent;
    try {
      if (backgroundColor.startsWith('#')) {
        return Color(int.parse(backgroundColor.replaceFirst('#', '0xFF')));
      } else if (backgroundColor.startsWith('0x')) {
        return Color(int.parse(backgroundColor));
      }
    } catch (e) {
      // ignore parsing errors
    }
    return Colors.blue;
  }

  // Build image widget for shared post - handles both network URLs and asset paths
  Widget _buildSharedPostImage(String imageUrl) {
    final errorWidget = Container(
      width: double.infinity,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );

    // Check if it's a local asset path
    if (imageUrl.startsWith('asset/') || imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    }

    // Check if it's a base64 data URL
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorWidget,
        );
      } catch (e) {
        return errorWidget;
      }
    }

    // Otherwise treat as network URL
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }

  void _showMessageOptions(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Copy option (for text messages only)
                if (message.type == MessageType.text)
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Sao chép'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép tin nhắn')),
                      );
                    },
                  ),

                // Forward option
                ListTile(
                  leading: const Icon(Icons.forward),
                  title: const Text('Chuyển tiếp'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onForward?.call(message);
                  },
                ),

                // Delete for me option
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Xóa ở phía bạn'),
                  subtitle: const Text(
                    'Tin nhắn sẽ bị xóa khỏi thiết bị của bạn',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteForMe(context);
                  },
                ),

                // Recall option (only for sender)
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.undo, color: Colors.red),
                    title: const Text(
                      'Thu hồi tin nhắn',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                      'Xóa tin nhắn với mọi người',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmRecall(context);
                    },
                  ),

                const SizedBox(height: 8),

                // Cancel button
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Hủy'),
                  onTap: () => Navigator.pop(context),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteForMe(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn?'),
        content: const Text(
          'Tin nhắn này sẽ bị xóa ở phía bạn. Người khác vẫn có thể nhìn thấy tin nhắn này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteForMe?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmRecall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thu hồi tin nhắn?'),
        content: const Text(
          'Tin nhắn này sẽ bị thu hồi với mọi người trong cuộc trò chuyện.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRecall?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
  }
}

/// Timestamp separator widget
class TimestampSeparator extends StatelessWidget {
  final DateTime timestamp;

  const TimestampSeparator({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          formatMessageTime(timestamp),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
