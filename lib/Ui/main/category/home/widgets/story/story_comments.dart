import 'package:flutter/material.dart';

void showStoryComments({
  required BuildContext context,
  required String friendName,
}) {
  final TextEditingController commentController = TextEditingController();

  // State cho reply
  int? replyingToIndex;
  String? replyingToUser;
  int? editingIndex;
  int? editingReplyParentIndex;
  int? editingReplyIndex;

  // Mock comments với replies
  final List<Map<String, dynamic>> comments = [
    {
      'user': 'Minh Anh',
      'avatar': 'asset/images/avatar.png',
      'comment': 'Đẹp quá! 😍',
      'time': '2 giờ trước',
      'likes': 12,
      'isLiked': false,
      'isOwn': false,
      'replies': <Map<String, dynamic>>[],
    },
    {
      'user': 'Hoàng Nam',
      'avatar': 'asset/images/avatar.png',
      'comment': 'Chỗ này ở đâu vậy bạn?',
      'time': '1 giờ trước',
      'likes': 5,
      'isLiked': false,
      'isOwn': false,
      'replies': <Map<String, dynamic>>[],
    },
    {
      'user': 'Thu Hà',
      'avatar': 'asset/images/avatar.png',
      'comment': 'Lần sau cho mình đi cùng với nha!',
      'time': '30 phút trước',
      'likes': 8,
      'isLiked': false,
      'isOwn': false,
      'replies': <Map<String, dynamic>>[],
    },
  ];

  // Đếm tổng số comment
  int getTotalComments() {
    int total = comments.length;
    for (var c in comments) {
      total += (c['replies'] as List).length;
    }
    return total;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        Widget buildComment(
          Map<String, dynamic> c,
          int commentIndex, {
          bool isReply = false,
          int? parentIndex,
          int? replyIndex,
        }) {
          final bool isLiked = c['isLiked'] as bool;
          final int likes = c['likes'] as int;
          final bool isOwn = c['isOwn'] as bool;
          final List<Map<String, dynamic>> replies = isReply
              ? []
              : List<Map<String, dynamic>>.from(c['replies'] as List);

          return GestureDetector(
            onLongPress: isOwn
                ? () {
                    _showCommentOptions(
                      context: context,
                      setModalState: setModalState,
                      comments: comments,
                      commentController: commentController,
                      c: c,
                      commentIndex: commentIndex,
                      isReply: isReply,
                      parentIndex: parentIndex,
                      replyIndex: replyIndex,
                      onEdit: () {
                        if (isReply) {
                          editingReplyParentIndex = parentIndex;
                          editingReplyIndex = replyIndex;
                          editingIndex = null;
                        } else {
                          editingIndex = commentIndex;
                          editingReplyParentIndex = null;
                          editingReplyIndex = null;
                        }
                        replyingToIndex = null;
                        commentController.text = c['comment'] as String;
                      },
                    );
                  }
                : null,
            child: Padding(
              padding: EdgeInsets.only(left: isReply ? 48 : 0, bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isReply ? 14 : 18,
                    backgroundImage: AssetImage(c['avatar'] as String),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              c['user'] as String,
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
                                  color: const Color(
                                    0xFF113953,
                                  ).withOpacity(0.1),
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
                              c['time'] as String,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: isReply ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['comment'] as String,
                          style: TextStyle(fontSize: isReply ? 13 : 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  c['isLiked'] = !isLiked;
                                  c['likes'] = isLiked ? likes - 1 : likes + 1;
                                });
                              },
                              child: Text(
                                isLiked ? 'Đã thích' : 'Thích',
                                style: TextStyle(
                                  color: isLiked
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (!isReply)
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    replyingToIndex = commentIndex;
                                    replyingToUser = c['user'] as String;
                                    editingIndex = null;
                                    editingReplyParentIndex = null;
                                    editingReplyIndex = null;
                                    commentController.clear();
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
                        // Hiện replies
                        if (!isReply && replies.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...replies.asMap().entries.map(
                            (entry) => buildComment(
                              entry.value,
                              commentIndex,
                              isReply: true,
                              parentIndex: commentIndex,
                              replyIndex: entry.key,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        c['isLiked'] = !isLiked;
                        c['likes'] = isLiked ? likes - 1 : likes + 1;
                      });
                    },
                    child: Column(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        Text(
                          '${c['likes']}',
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${getTotalComments()} bình luận',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, i) => buildComment(comments[i], i),
                ),
              ),
              // Reply indicator
              if (replyingToIndex != null ||
                  editingIndex != null ||
                  editingReplyParentIndex != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Text(
                        editingIndex != null || editingReplyParentIndex != null
                            ? 'Đang sửa bình luận'
                            : 'Đang trả lời $replyingToUser',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            replyingToIndex = null;
                            replyingToUser = null;
                            editingIndex = null;
                            editingReplyParentIndex = null;
                            editingReplyIndex = null;
                            commentController.clear();
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
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage('asset/images/avatar.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: replyingToIndex != null
                                ? 'Trả lời $replyingToUser...'
                                : editingIndex != null ||
                                      editingReplyParentIndex != null
                                ? 'Sửa bình luận...'
                                : 'Thêm bình luận cho $friendName...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (commentController.text.trim().isNotEmpty) {
                            setModalState(() {
                              if (editingIndex != null) {
                                comments[editingIndex!]['comment'] =
                                    commentController.text;
                                editingIndex = null;
                              } else if (editingReplyParentIndex != null &&
                                  editingReplyIndex != null) {
                                (comments[editingReplyParentIndex!]['replies']
                                        as List)[editingReplyIndex!]['comment'] =
                                    commentController.text;
                                editingReplyParentIndex = null;
                                editingReplyIndex = null;
                              } else if (replyingToIndex != null) {
                                (comments[replyingToIndex!]['replies'] as List)
                                    .add({
                                      'user': 'Bạn',
                                      'avatar': 'asset/images/avatar.png',
                                      'comment': commentController.text,
                                      'time': 'Vừa xong',
                                      'likes': 0,
                                      'isLiked': false,
                                      'isOwn': true,
                                    });
                                replyingToIndex = null;
                                replyingToUser = null;
                              } else {
                                comments.add({
                                  'user': 'Bạn',
                                  'avatar': 'asset/images/avatar.png',
                                  'comment': commentController.text,
                                  'time': 'Vừa xong',
                                  'likes': 0,
                                  'isLiked': false,
                                  'isOwn': true,
                                  'replies': <Map<String, dynamic>>[],
                                });
                              }
                            });
                            commentController.clear();
                          }
                        },
                        child: Text(
                          editingIndex != null ||
                                  editingReplyParentIndex != null
                              ? 'Lưu'
                              : 'Đăng',
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
      },
    ),
  );
}

void _showCommentOptions({
  required BuildContext context,
  required StateSetter setModalState,
  required List<Map<String, dynamic>> comments,
  required TextEditingController commentController,
  required Map<String, dynamic> c,
  required int commentIndex,
  required bool isReply,
  int? parentIndex,
  int? replyIndex,
  required VoidCallback onEdit,
}) {
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
                setModalState(onEdit);
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
                showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('Xóa bình luận'),
                    content: const Text('Bạn có chắc muốn xóa bình luận này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx2);
                          setModalState(() {
                            if (isReply &&
                                parentIndex != null &&
                                replyIndex != null) {
                              (comments[parentIndex]['replies'] as List)
                                  .removeAt(replyIndex);
                            } else {
                              comments.removeAt(commentIndex);
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
