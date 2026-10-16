import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final List<String> likes;
  final String? parentCommentId;
  final int replyCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.likes = const [],
    this.parentCommentId,
    this.replyCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safe list parsing helper
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      return [];
    }
    
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      likes: safeStringList(data['likes']),
      parentCommentId: data['parentCommentId'],
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'likes': likes,
      'parentCommentId': parentCommentId,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    List<String>? likes,
    String? parentCommentId,
    int? replyCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
