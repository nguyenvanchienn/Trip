import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/data/firebase/firebase_story_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

void showStoryComments({
  required BuildContext context,
  required String storyId,
  required String friendName,
  String? currentUserName,
  String? currentUserPhotoUrl,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _StoryCommentsSheet(
      storyId: storyId,
      friendName: friendName,
      currentUserName: currentUserName,
      currentUserPhotoUrl: currentUserPhotoUrl,
    ),
  );
}

class _StoryCommentsSheet extends StatefulWidget {
  final String storyId;
  final String friendName;
  final String? currentUserName;
  final String? currentUserPhotoUrl;

  const _StoryCommentsSheet({
    required this.storyId,
    required this.friendName,
    this.currentUserName,
    this.currentUserPhotoUrl,
  });

  @override
  State<_StoryCommentsSheet> createState() => _StoryCommentsSheetState();
}

class _StoryCommentsSheetState extends State<_StoryCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseStoryService _storyService = FirebaseStoryService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  String? _replyingToCommentId;
  String? _replyingToUser;
  String? _editingCommentId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      if (_editingCommentId != null) {
        // Edit existing comment
        await _storyService.editStoryComment(
          widget.storyId,
          _editingCommentId!,
          content,
        );
        _editingCommentId = null;
      } else {
        // Add new comment or reply
        await _storyService.addStoryComment(
          storyId: widget.storyId,
          content: content,
          authorName: widget.currentUserName ?? 'Bạn',
          authorPhotoUrl: widget.currentUserPhotoUrl,
          parentCommentId: _replyingToCommentId,
        );
        _replyingToCommentId = null;
        _replyingToUser = null;
      }
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleLike(String commentId, List<String> likes) async {
    if (_currentUserId == null) return;

    try {
      if (likes.contains(_currentUserId)) {
        await _storyService.unlikeStoryComment(widget.storyId, commentId);
      } else {
        await _storyService.likeStoryComment(widget.storyId, commentId);
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storyService.deleteStoryComment(widget.storyId, commentId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCommentOptions(Map<String, dynamic> comment) {
    final isOwn = comment['authorId'] == _currentUserId;
    if (!isOwn) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF113953)),
                title: const Text('Sửa bình luận'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _editingCommentId = comment['id'];
                    _commentController.text = comment['content'] ?? '';
                    _replyingToCommentId = null;
                    _replyingToUser = null;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Xóa bình luận',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteComment(comment['id']);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(
    Map<String, dynamic> comment, {
    bool isReply = false,
  }) {
    final authorId = comment['authorId'] as String?;
    final authorName = comment['authorName'] as String? ?? 'Ẩn danh';
    final authorPhotoUrl = comment['authorPhotoUrl'] as String?;
    final content = comment['content'] as String? ?? '';
    final likes = List<String>.from(comment['likes'] ?? []);
    final createdAt =
        (comment['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final isOwn = authorId == _currentUserId;
    final isLiked = likes.contains(_currentUserId);
    final commentId = comment['id'] as String;
    final replyCount = (comment['replyCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onLongPress: isOwn ? () => _showCommentOptions(comment) : null,
      child: Padding(
        padding: EdgeInsets.only(left: isReply ? 48 : 0, bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: isReply ? 14 : 18,
              backgroundColor: Colors.grey[300],
              child: ClipOval(
                child:
                    authorPhotoUrl != null &&
                        authorPhotoUrl.isNotEmpty &&
                        getImageProvider(authorPhotoUrl) != null
                    ? Image(
                        image: getImageProvider(authorPhotoUrl)!,
                        fit: BoxFit.cover,
                        width: isReply ? 28 : 36,
                        height: isReply ? 28 : 36,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: isReply ? 16 : 20,
                          color: Colors.grey[600],
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: isReply ? 16 : 20,
                        color: Colors.grey[600],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isReply ? 13 : 14,
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF113953).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Bạn',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF113953),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: isReply ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(content, style: TextStyle(fontSize: isReply ? 13 : 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleLike(commentId, likes),
                        child: Text(
                          isLiked ? 'Đã thích' : 'Thích',
                          style: TextStyle(
                            color: isLiked ? Colors.red : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!isReply)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = commentId;
                              _replyingToUser = authorName;
                              _editingCommentId = null;
                              _commentController.clear();
                            });
                          },
                          child: Text(
                            'Trả lời',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Show replies
                  if (!isReply && replyCount > 0) ...[
                    const SizedBox(height: 8),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _storyService.getCommentReplies(
                        widget.storyId,
                        commentId,
                      ),
                      builder: (context, snapshot) {
                        final replies = snapshot.data ?? [];
                        return Column(
                          children: replies
                              .map(
                                (reply) =>
                                    _buildCommentItem(reply, isReply: true),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleLike(commentId, likes),
              child: Column(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  Text(
                    '${likes.length}',
                    style: TextStyle(
                      color: isLiked ? Colors.red : Colors.grey[500],
                      fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with comment count
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _storyService.getStoryComments(widget.storyId),
            builder: (context, snapshot) {
              final comments = snapshot.data ?? [];
              int totalCount = comments.length;
              for (var c in comments) {
                totalCount += (c['replyCount'] as num?)?.toInt() ?? 0;
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$totalCount bình luận',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          // Comments list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _storyService.getStoryComments(widget.storyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bình luận nào',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy là người đầu tiên bình luận!',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) =>
                      _buildCommentItem(comments[index]),
                );
              },
            ),
          ),
          // Reply/Edit indicator
          if (_replyingToCommentId != null || _editingCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Text(
                    _editingCommentId != null
                        ? 'Đang sửa bình luận'
                        : 'Đang trả lời $_replyingToUser',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingToCommentId = null;
                        _replyingToUser = null;
                        _editingCommentId = null;
                        _commentController.clear();
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child:
                          widget.currentUserPhotoUrl != null &&
                              widget.currentUserPhotoUrl!.isNotEmpty &&
                              getImageProvider(widget.currentUserPhotoUrl!) !=
                                  null
                          ? Image(
                              image: getImageProvider(
                                widget.currentUserPhotoUrl!,
                              )!,
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: _replyingToCommentId != null
                            ? 'Trả lời $_replyingToUser...'
                            : _editingCommentId != null
                            ? 'Sửa bình luận...'
                            : 'Thêm bình luận cho ${widget.friendName}...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitComment,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _editingCommentId != null ? 'Lưu' : 'Đăng',
                            style: const TextStyle(
                              color: Color(0xFF113953),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
