import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model cho một hoạt động/tương tác
class ActivityItem {
  final String id;
  final String type; // 'comment', 'like', 'mention', 'tag', 'message'
  final String? postId;
  final String? postTitle;
  final String? postPhotoUrl;
  final String? targetUserId;
  final String? targetUserName;
  final String? targetUserPhotoUrl;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityItem({
    required this.id,
    required this.type,
    this.postId,
    this.postTitle,
    this.postPhotoUrl,
    this.targetUserId,
    this.targetUserName,
    this.targetUserPhotoUrl,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityItem(
      id: doc.id,
      type: data['type'] ?? '',
      postId: data['postId'],
      postTitle: data['postTitle'],
      postPhotoUrl: data['postPhotoUrl'],
      targetUserId: data['targetUserId'],
      targetUserName: data['targetUserName'],
      targetUserPhotoUrl: data['targetUserPhotoUrl'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'postId': postId,
      'postTitle': postTitle,
      'postPhotoUrl': postPhotoUrl,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'targetUserPhotoUrl': targetUserPhotoUrl,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

/// Model cho lịch sử tìm kiếm
class SearchHistoryItem {
  final String id;
  final String query;
  final String type; // 'user', 'post', 'trip', 'location'
  final DateTime timestamp;
  final String? resultId;
  final String? resultTitle;
  final String? resultPhotoUrl;

  SearchHistoryItem({
    required this.id,
    required this.query,
    required this.type,
    required this.timestamp,
    this.resultId,
    this.resultTitle,
    this.resultPhotoUrl,
  });

  factory SearchHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SearchHistoryItem(
      id: doc.id,
      query: data['query'] ?? '',
      type: data['type'] ?? 'user',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resultId: data['resultId'],
      resultTitle: data['resultTitle'],
      resultPhotoUrl: data['resultPhotoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'query': query,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'resultId': resultId,
      'resultTitle': resultTitle,
      'resultPhotoUrl': resultPhotoUrl,
    };
  }
}

/// Service quản lý hoạt động và lịch sử của người dùng
class FirebaseActivityService {
  // Singleton pattern
  static final FirebaseActivityService _instance =
      FirebaseActivityService._internal();
  factory FirebaseActivityService() => _instance;
  FirebaseActivityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  CollectionReference<Map<String, dynamic>> get _tripsCollection =>
      _firestore.collection('trips');

  CollectionReference<Map<String, dynamic>> get _storiesCollection =>
      _firestore.collection('stories');

  CollectionReference<Map<String, dynamic>> get _conversationsCollection =>
      _firestore.collection('conversations');

  /// Lấy các bình luận của người dùng hiện tại
  Future<List<ActivityItem>> getMyComments({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collectionGroup('comments')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ActivityItem(
        id: doc.id,
        type: 'comment',
        postId: data['postId'] ?? doc.reference.parent.parent?.id,
        content: data['content'] ?? '',
        timestamp:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  /// Lấy các lượt thích của người dùng hiện tại
  Future<List<ActivityItem>> getMyLikes({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _postsCollection
        .where('likes', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ActivityItem(
        id: doc.id,
        type: 'like',
        postId: doc.id,
        postTitle: data['title'],
        postPhotoUrl: data['photoUrl'],
        content: 'Đã thích bài viết này',
        timestamp:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  /// Lấy tất cả tương tác (bình luận + lượt thích)
  Future<List<ActivityItem>> getMyInteractions({int limit = 50}) async {
    final comments = await getMyComments(limit: limit ~/ 2);
    final likes = await getMyLikes(limit: limit ~/ 2);

    final all = [...comments, ...likes];
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }

  /// Lấy các bài viết được gắn thẻ hoặc nhắc đến
  Future<List<ActivityItem>> getTaggedActivities({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    // Lấy các bài viết được gắn thẻ
    final taggedPosts = await _postsCollection
        .where('taggedUsers', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    // Lấy các bình luận nhắc đến
    final mentionedComments = await _firestore
        .collectionGroup('comments')
        .where('mentions', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final activities = <ActivityItem>[];

    for (final doc in taggedPosts.docs) {
      final data = doc.data();
      activities.add(
        ActivityItem(
          id: doc.id,
          type: 'tag',
          postId: doc.id,
          postTitle: data['title'],
          postPhotoUrl: data['photoUrl'],
          targetUserId: data['userId'],
          content: 'Đã gắn thẻ bạn trong bài viết',
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      );
    }

    for (final doc in mentionedComments.docs) {
      final data = doc.data();
      activities.add(
        ActivityItem(
          id: doc.id,
          type: 'mention',
          postId: data['postId'] ?? doc.reference.parent.parent?.id,
          targetUserId: data['userId'],
          content: data['content'] ?? '',
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      );
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }

  /// Lấy tất cả tin nhắn đã gửi và nhận
  Future<List<ActivityItem>> getMessages({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    // Lấy các cuộc trò chuyện của người dùng
    final conversations = await _conversationsCollection
        .where('participants', arrayContains: uid)
        .get();

    final activities = <ActivityItem>[];

    for (final convDoc in conversations.docs) {
      final messagesSnapshot = await convDoc.reference
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      for (final msgDoc in messagesSnapshot.docs) {
        final data = msgDoc.data();
        activities.add(
          ActivityItem(
            id: msgDoc.id,
            type: 'message',
            targetUserId: data['senderId'] == uid
                ? data['receiverId']
                : data['senderId'],
            targetUserName: data['senderName'],
            content: data['content'] ?? '',
            timestamp:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            metadata: {
              'conversationId': convDoc.id,
              'isSent': data['senderId'] == uid,
            },
          ),
        );
      }
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }

  /// Lấy các tin đã đăng
  Future<List<ActivityItem>> getMyStories({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _storiesCollection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ActivityItem(
        id: doc.id,
        type: 'story',
        postPhotoUrl: data['mediaUrl'],
        content: data['caption'] ?? 'Tin',
        timestamp:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata: {
          'viewCount': data['viewCount'] ?? 0,
          'isExpired':
              data['expiresAt'] != null &&
              (data['expiresAt'] as Timestamp).toDate().isBefore(
                DateTime.now(),
              ),
        },
      );
    }).toList();
  }

  /// Lấy các bài viết của người dùng
  Future<List<ActivityItem>> getMyPosts({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _postsCollection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ActivityItem(
        id: doc.id,
        type: 'post',
        postId: doc.id,
        postTitle: data['title'],
        postPhotoUrl:
            data['photoUrl'] ??
            (data['photos'] is List && (data['photos'] as List).isNotEmpty
                ? (data['photos'] as List).first
                : null),
        content: data['content'] ?? data['description'] ?? '',
        timestamp:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata: {
          'likeCount': (data['likes'] as List?)?.length ?? 0,
          'commentCount': data['commentCount'] ?? 0,
        },
      );
    }).toList();
  }

  /// Lấy các bài viết đã lưu
  Future<List<ActivityItem>> getSavedPosts({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final userDoc = await _usersCollection.doc(uid).get();
    final savedIds = List<String>.from(userDoc.data()?['savedPosts'] ?? []);

    if (savedIds.isEmpty) return [];

    // Firestore chỉ cho phép 10 items trong whereIn
    final batches = <List<String>>[];
    for (var i = 0; i < savedIds.length; i += 10) {
      batches.add(
        savedIds.sublist(
          i,
          i + 10 > savedIds.length ? savedIds.length : i + 10,
        ),
      );
    }

    final activities = <ActivityItem>[];
    for (final batch in batches) {
      final snapshot = await _postsCollection
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        activities.add(
          ActivityItem(
            id: doc.id,
            type: 'saved',
            postId: doc.id,
            postTitle: data['title'],
            postPhotoUrl: data['photoUrl'],
            content: data['content'] ?? '',
            timestamp:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      }
    }

    return activities.take(limit).toList();
  }

  /// Lấy các collection (bộ sưu tập)
  Future<List<Map<String, dynamic>>> getCollections() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _usersCollection
        .doc(uid)
        .collection('collections')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Lấy các chuyến đi đã tạo
  Future<List<ActivityItem>> getMyTrips({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _tripsCollection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ActivityItem(
        id: doc.id,
        type: 'trip',
        postId: doc.id,
        postTitle: data['title'] ?? data['name'],
        postPhotoUrl: data['photoUrl'] ?? data['coverUrl'],
        content: data['description'] ?? '',
        timestamp:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata: {
          'destination': data['destination'],
          'startDate': data['startDate'],
          'endDate': data['endDate'],
          'isPublished': data['isPublished'] ?? false,
        },
      );
    }).toList();
  }

  /// Lấy lịch sử tìm kiếm
  Future<List<SearchHistoryItem>> getSearchHistory({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _usersCollection
        .doc(uid)
        .collection('search_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SearchHistoryItem.fromFirestore(doc))
        .toList();
  }

  /// Thêm mục tìm kiếm mới
  Future<void> addSearchHistory({
    required String query,
    required String type,
    String? resultId,
    String? resultTitle,
    String? resultPhotoUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).collection('search_history').add({
      'query': query,
      'type': type,
      'timestamp': Timestamp.now(),
      'resultId': resultId,
      'resultTitle': resultTitle,
      'resultPhotoUrl': resultPhotoUrl,
    });
  }

  /// Xóa một mục tìm kiếm
  Future<void> deleteSearchHistoryItem(String itemId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection
        .doc(uid)
        .collection('search_history')
        .doc(itemId)
        .delete();
  }

  /// Xóa tất cả lịch sử tìm kiếm
  Future<void> clearSearchHistory() async {
    final uid = currentUserId;
    if (uid == null) return;

    final snapshot = await _usersCollection
        .doc(uid)
        .collection('search_history')
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Lấy lịch sử các lần được nhắc đến
  Future<List<ActivityItem>> getMentionHistory({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final activities = <ActivityItem>[];

    // Lấy từ bình luận
    final commentMentions = await _firestore
        .collectionGroup('comments')
        .where('mentions', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (final doc in commentMentions.docs) {
      final data = doc.data();
      activities.add(
        ActivityItem(
          id: doc.id,
          type: 'mention_comment',
          postId: data['postId'] ?? doc.reference.parent.parent?.id,
          targetUserId: data['userId'],
          targetUserName: data['userName'],
          content: data['content'] ?? '',
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      );
    }

    // Lấy từ bài viết
    final postMentions = await _postsCollection
        .where('mentions', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (final doc in postMentions.docs) {
      final data = doc.data();
      activities.add(
        ActivityItem(
          id: doc.id,
          type: 'mention_post',
          postId: doc.id,
          postTitle: data['title'],
          postPhotoUrl: data['photoUrl'],
          targetUserId: data['userId'],
          content: data['content'] ?? '',
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      );
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }

  /// Lấy lịch sử hoạt động tài khoản (đăng nhập, thay đổi)
  Future<List<Map<String, dynamic>>> getAccountHistory({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _usersCollection
        .doc(uid)
        .collection('account_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Kiểm tra bài viết đã được lưu chưa
  Future<bool> isPostSaved(String postId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final userDoc = await _usersCollection.doc(uid).get();
    final savedIds = List<String>.from(userDoc.data()?['savedPosts'] ?? []);
    return savedIds.contains(postId);
  }

  /// Lưu/Bỏ lưu bài viết
  Future<bool> toggleSavePost(String postId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final userDoc = await _usersCollection.doc(uid).get();
    final savedIds = List<String>.from(userDoc.data()?['savedPosts'] ?? []);

    final isSaved = savedIds.contains(postId);

    if (isSaved) {
      // Bỏ lưu
      await _usersCollection.doc(uid).set({
        'savedPosts': FieldValue.arrayRemove([postId]),
      }, SetOptions(merge: true));
      return false;
    } else {
      // Lưu bài viết
      await _usersCollection.doc(uid).set({
        'savedPosts': FieldValue.arrayUnion([postId]),
      }, SetOptions(merge: true));
      return true;
    }
  }

  /// Lưu bài viết
  Future<void> savePost(String postId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).set({
      'savedPosts': FieldValue.arrayUnion([postId]),
    }, SetOptions(merge: true));
  }

  /// Bỏ lưu bài viết
  Future<void> unsavePost(String postId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).set({
      'savedPosts': FieldValue.arrayRemove([postId]),
    }, SetOptions(merge: true));
  }
}
