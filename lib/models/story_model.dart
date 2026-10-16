import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryType { image, video, live }

class StoryModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl; // URL to image/video in Firebase Storage
  final StoryType type;
  final String? caption;
  final String? location;
  final String? country;
  final DateTime createdAt;
  final DateTime expiresAt; // Stories expire after 24 hours
  final List<String> likes;
  final List<String> viewers; // Users who have viewed the story
  final int commentCount;
  final bool isLive;
  final String? liveStreamId; // For live streams

  StoryModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.mediaUrl,
    required this.type,
    this.caption,
    this.location,
    this.country,
    required this.createdAt,
    required this.expiresAt,
    this.likes = const [],
    this.viewers = const [],
    this.commentCount = 0,
    this.isLive = false,
    this.liveStreamId,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      mediaUrl: data['mediaUrl'] ?? '',
      type: StoryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => StoryType.image,
      ),
      caption: data['caption'],
      location: data['location'],
      country: data['country'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      likes: List<String>.from(data['likes'] ?? []),
      viewers: List<String>.from(data['viewers'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      isLive: data['isLive'] ?? false,
      liveStreamId: data['liveStreamId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'mediaUrl': mediaUrl,
      'type': type.name,
      'caption': caption,
      'location': location,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'likes': likes,
      'viewers': viewers,
      'commentCount': commentCount,
      'isLive': isLive,
      'liveStreamId': liveStreamId,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  StoryModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? mediaUrl,
    StoryType? type,
    String? caption,
    String? location,
    String? country,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? likes,
    List<String>? viewers,
    int? commentCount,
    bool? isLive,
    String? liveStreamId,
  }) {
    return StoryModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      likes: likes ?? this.likes,
      viewers: viewers ?? this.viewers,
      commentCount: commentCount ?? this.commentCount,
      isLive: isLive ?? this.isLive,
      liveStreamId: liveStreamId ?? this.liveStreamId,
    );
  }
}
