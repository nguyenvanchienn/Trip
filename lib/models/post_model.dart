import 'package:cloud_firestore/cloud_firestore.dart';

enum PostAudience { public, friends, onlyMe }

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final List<String> mediaUrls;
  final String? backgroundColor;
  final PostAudience audience;
  final String? location;
  final List<String> hashtags;
  final List<String> taggedUsers;
  final List<String> likes;
  final int commentCount;
  final int shareCount;
  final List<String> sharedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final bool isSharedToStory;
  final bool isPinned; // whether user has pinned this post on their profile
  final bool allowComments; // whether others may comment
  final List<String> albumIds; // ids of albums this post belongs to
  final int
  layoutIndex; // 0: Grid 2 cột, 1: Ảnh đơn, 2: Cuộn ngang, 3: 1 lớn + 2 nhỏ
  final String? tripId; // optional associated trip
  final List<Map<String, dynamic>> experienceEntries; // Chia sẻ kinh nghiệm
  final String?
  sharedPostId; // ID của bài viết gốc được chia sẻ (nếu là shared post)
  final Map<String, dynamic>? sharedPostData; // Dữ liệu bài viết gốc được nhúng

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.mediaUrls = const [],
    this.backgroundColor,
    this.audience = PostAudience.public,
    this.location,
    this.tripId,
    this.hashtags = const [],
    this.taggedUsers = const [],
    this.likes = const [],
    this.commentCount = 0,
    this.shareCount = 0,
    this.sharedBy = const [],
    required this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.isSharedToStory = false,
    this.isPinned = false,
    this.allowComments = true,
    this.albumIds = const [],
    this.layoutIndex = 0,
    this.experienceEntries = const [],
    this.sharedPostId,
    this.sharedPostData,
  });

  /// Check if this post is a shared post (has embedded original post)
  bool get isSharedPost => sharedPostId != null && sharedPostId!.isNotEmpty;

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safe list parsing helper
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      return [];
    }

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      mediaUrls: safeStringList(data['mediaUrls']),
      backgroundColor: data['backgroundColor']?.toString(),
      audience: PostAudience.values.firstWhere(
        (e) => e.name == data['audience'],
        orElse: () => PostAudience.public,
      ),
      location: data['location'],
      hashtags: safeStringList(data['hashtags']),
      taggedUsers: safeStringList(data['taggedUsers']),
      likes: safeStringList(data['likes']),
      commentCount:
          (data['commentCount'] as num?)?.toInt() ??
          (data['commentsCount'] as num?)?.toInt() ??
          0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      sharedBy: safeStringList(data['sharedBy']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      isSharedToStory: data['isSharedToStory'] ?? false,
      isPinned: data['isPinned'] ?? false,
      allowComments: data['allowComments'] ?? true,
      albumIds: safeStringList(data['albumIds']),
      layoutIndex: (data['layoutIndex'] as num?)?.toInt() ?? 0,
      tripId: data['tripId'] as String?,
      experienceEntries:
          (data['experienceEntries'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      sharedPostId: data['sharedPostId'] as String?,
      sharedPostData: data['sharedPostData'] != null
          ? Map<String, dynamic>.from(data['sharedPostData'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'mediaUrls': mediaUrls,
      'backgroundColor': backgroundColor,
      'audience': audience.name,
      'location': location,
      'tripId': tripId,
      'taggedUsers': taggedUsers,
      'likes': likes,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'sharedBy': sharedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'scheduledAt': scheduledAt != null
          ? Timestamp.fromDate(scheduledAt!)
          : null,
      'isSharedToStory': isSharedToStory,
      'isPinned': isPinned,
      'allowComments': allowComments,
      'albumIds': albumIds,
      'layoutIndex': layoutIndex,
      'hashtags': hashtags,
      'experienceEntries': experienceEntries,
      'sharedPostId': sharedPostId,
      'sharedPostData': sharedPostData,
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    List<String>? mediaUrls,
    String? backgroundColor,
    PostAudience? audience,
    String? location,
    List<String>? hashtags,
    List<String>? taggedUsers,
    List<String>? likes,
    int? commentCount,
    int? shareCount,
    List<String>? sharedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    bool? isSharedToStory,
    bool? isPinned,
    bool? allowComments,
    List<String>? albumIds,
    int? layoutIndex,
    List<Map<String, dynamic>>? experienceEntries,
    String? sharedPostId,
    Map<String, dynamic>? sharedPostData,
  }) {
    return PostModel(
      isSharedToStory: isSharedToStory ?? this.isSharedToStory,
      isPinned: isPinned ?? this.isPinned,
      allowComments: allowComments ?? this.allowComments,
      albumIds: albumIds ?? this.albumIds,
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      audience: audience ?? this.audience,
      location: location ?? this.location,
      hashtags: hashtags ?? this.hashtags,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      sharedBy: sharedBy ?? this.sharedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      layoutIndex: layoutIndex ?? this.layoutIndex,
      tripId: tripId ?? tripId,
      experienceEntries: experienceEntries ?? this.experienceEntries,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      sharedPostData: sharedPostData ?? this.sharedPostData,
    );
  }

  bool isLikedBy(String userId) => likes.contains(userId);
}
