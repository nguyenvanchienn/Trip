import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../models/notification_model.dart';
import 'firebase_notification_service.dart';

class FirebasePostService {
  // Singleton pattern để share cache giữa các instances
  static final FirebasePostService _instance = FirebasePostService._internal();
  factory FirebasePostService() => _instance;
  FirebasePostService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache blocked users để tránh fetch mỗi snapshot (gây treo UI)
  List<String> _cachedBlockedUsers = [];
  DateTime? _blockedCacheTime;
  static const _blockedCacheDuration = Duration(minutes: 5);

  // Tham chiếu collection
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  String? get currentUserId => _auth.currentUser?.uid;

  // Lấy blocked users với cache để tránh blocking
  Future<List<String>> _getBlockedUsers() async {
    final uid = currentUserId;
    if (uid == null) return [];

    // Trả về cache nếu còn valid
    final now = DateTime.now();
    if (_blockedCacheTime != null &&
        now.difference(_blockedCacheTime!) < _blockedCacheDuration &&
        _cachedBlockedUsers.isNotEmpty) {
      return _cachedBlockedUsers;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      _cachedBlockedUsers = List<String>.from(userDoc.data()?['blocked'] ?? []);
      _blockedCacheTime = now;
    } catch (e) {
      print('Error fetching blocked users: $e');
      // Return cached value on error
    }
    return _cachedBlockedUsers;
  }

  // Refresh blocked users cache (gọi khi block/unblock)
  void invalidateBlockedCache() {
    _blockedCacheTime = null;
  }

  // Kiểm tra xem byte có đại diện cho file video qua magic bytes
  bool _isVideo(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // MP4/MOV: bắt đầu với ftyp tại offset 4
    if (bytes.length > 8 &&
        bytes[4] == 0x66 && // ký tự f
        bytes[5] == 0x74 && // ký tự t
        bytes[6] == 0x79 && // ký tự y
        bytes[7] == 0x70) {
      // p
      return true;
    }

    // AVI: bắt đầu với RIFF...AVI
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes.length > 11 &&
        bytes[8] == 0x41 &&
        bytes[9] == 0x56 &&
        bytes[10] == 0x49) {
      return true;
    }

    // WebM/MKV: bắt đầu với 0x1A45DFA3
    if (bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      return true;
    }

    return false;
  }

  // Tải video lên Firebase Storage và trả về URL
  Future<String?> _uploadVideoToStorage(
    Uint8List videoBytes,
    String postId,
    int index,
  ) async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;

      final ref = _storage.ref().child('posts/$uid/$postId/video_$index.mp4');
      final uploadTask = await ref.putData(
        videoBytes,
        SettableMetadata(contentType: 'video/mp4'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  // Nén ảnh để giảm kích thước lưu Firestore
  Uint8List _compressImage(
    Uint8List bytes, {
    int maxWidth = 800,
    int quality = 70,
  }) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Thay đổi kích thước nếu quá lớn
      img.Image resized;
      if (image.width > maxWidth) {
        resized = img.copyResize(image, width: maxWidth);
      } else {
        resized = image;
      }

      // Mã hóa thành JPEG với nén
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      print('Error compressing image: $e');
      return bytes;
    }
  }

  // Tạo bài viết
  Future<PostModel?> createPost({
    required String content,
    required String authorName,
    String? authorPhotoUrl,
    List<Uint8List>? mediaBytes,
    String? backgroundColor,
    PostAudience audience = PostAudience.public,
    String? location,
    String? tripId,
    List<String>? hashtags,
    int layoutIndex = 0,
    List<Map<String, dynamic>>? experienceEntries,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    // Tạo ID bài viết trước để dùng cho đường dẫn upload video
    final docRef = _postsCollection.doc();
    final postId = docRef.id;

    List<String> mediaUrls = [];

    // Xử lý media (ảnh và video)
    if (mediaBytes != null && mediaBytes.isNotEmpty) {
      print('Processing ${mediaBytes.length} media files...');
      for (int i = 0; i < mediaBytes.length; i++) {
        try {
          final bytes = mediaBytes[i];
          print('Processing media $i, size: ${bytes.length} bytes');

          // Kiểm tra xem đây có phải video không
          if (_isVideo(bytes)) {
            print('Detected video file, uploading to Firebase Storage...');
            final videoUrl = await _uploadVideoToStorage(bytes, postId, i);
            if (videoUrl != null) {
              mediaUrls.add(videoUrl);
              print('Video uploaded: $videoUrl');
            } else {
              print('Failed to upload video $i');
            }
          } else {
            // Là ảnh - nén và chuyển sang base64
            print('Processing as image...');
            final compressedBytes = _compressImage(bytes);
            print('Compressed size: ${compressedBytes.length} bytes');

            // Chuyển sang URL dữ liệu base64
            final base64String = base64Encode(compressedBytes);
            final dataUrl = 'data:image/jpeg;base64,$base64String';

            print('Base64 URL length: ${dataUrl.length} chars');
            mediaUrls.add(dataUrl);
          }
        } catch (e) {
          print('Error processing media $i: $e');
          // Tiếp tục với media khác thay vì lỗi hoàn toàn
          continue;
        }
      }
      print('All media processed successfully');
    }

    final post = PostModel(
      id: postId,
      authorId: uid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      mediaUrls: mediaUrls,
      backgroundColor: backgroundColor,
      audience: audience,
      location: location,
      tripId: tripId,
      hashtags: hashtags ?? [],
      createdAt: DateTime.now(),
      isPinned: false,
      allowComments: true,
      albumIds: [],
      layoutIndex: layoutIndex,
      experienceEntries: experienceEntries ?? [],
    );

    await docRef.set(post.toFirestore());

    // Gửi thông báo nhắc đến
    await _sendMentionNotifications(
      content: content,
      postId: postId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
    );

    return post;
  }

  // Trích xuất mention và gửi thông báo
  Future<void> _sendMentionNotifications({
    required String content,
    required String postId,
    required String authorName,
    String? authorPhotoUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    // Regex để khớp @Tên (tên tiếng Việt có nhiều từ)
    final mentionPattern = RegExp(
      r'@([A-ZĐÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴ][a-zA-ZàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ]*(?:\s+[A-ZĐÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴ][a-zA-ZàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ]*)*)',
    );

    final matches = mentionPattern.allMatches(content);
    final mentionedNames = <String>{};

    for (final match in matches) {
      final name = match.group(1)?.trim();
      if (name != null && name.isNotEmpty) {
        mentionedNames.add(name);
      }
    }

    if (mentionedNames.isEmpty) return;

    // Tìm người dùng theo tên hiển thị và gửi thông báo
    for (final displayName in mentionedNames) {
      try {
        // Tìm kiếm người dùng theo tên hiển thị
        final querySnapshot = await _firestore
            .collection('users')
            .where('displayName', isEqualTo: displayName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final recipientId = querySnapshot.docs.first.id;

          // Không thông báo cho chính bạn
          if (recipientId != uid) {
            await FirebaseNotificationService().sendNotification(
              recipientId: recipientId,
              message: '$authorName đã nhắc đến bạn trong một bài viết',
              type: NotificationType.mention,
              senderName: authorName,
              senderPhotoUrl: authorPhotoUrl,
              extraData: {'postId': postId},
            );
          }
        }
      } catch (e) {
        print('Error sending mention notification to $displayName: $e');
      }
    }
  }

  // Lấy bài viết theo ID
  Future<PostModel?> getPostById(String postId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (doc.exists) {
      return PostModel.fromFirestore(doc);
    }
    return null;
  }

  // Update post
  Future<void> updatePost(PostModel post) async {
    final data = <String, dynamic>{
      'content': post.content,
      'backgroundColor': post.backgroundColor,
      'audience': post.audience.name,
      'isEdited': true,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    };
    // thêm các trường tùy chọn nếu khác mặc định
    data['isPinned'] = post.isPinned;
    data['allowComments'] = post.allowComments;
    data['albumIds'] = post.albumIds;

    await _postsCollection.doc(post.id).update(data);
  }

  /// Ghim hoặc bỏ ghim một bài viết, đảm bảo chỉ một bài của mỗi tác giả được ghim tại một thời điểm.
  /// Khi nhiều yêu cầu ghim xảy ra liên tiếp, chúng ta giữ lại yêu cầu có timestamp mới nhất từ phía client.
  /// Một collection `userPins` riêng lưu bài ghim hiện tại + thời gian cập nhật.
  Future<void> pinPost(String postId, {required bool pinned}) async {
    final now = DateTime.now();
    final postRef = _postsCollection.doc(postId);

    // Chúng ta cần thay đổi tất cả bài ghim của tác giả trong một transaction,
    // nhưng Firestore không cho phép truy vấn bên trong transaction.
    // Để khắc phục, thực hiện truy vấn trước rồi áp dụng
    // cập nhật cho từng tài liệu trả về trong transaction.

    // đọc post và tài liệu userPins bên ngoài transaction để có thể
    // đánh giá tác giả và có thể timestamp yêu cầu mới hơn.
    final postSnap = await postRef.get();
    if (!postSnap.exists) return;
    final author = postSnap.data()?['authorId'] as String?;
    if (author == null) return;

    final pinDocRef = FirebaseFirestore.instance
        .collection('userPins')
        .doc(author);

    final pinSnap = await pinDocRef.get();
    DateTime? existingTime;
    if (pinSnap.exists) {
      final ts = pinSnap.data()?['updatedAt'] as Timestamp?;
      existingTime = ts?.toDate();
    }

    if (existingTime != null && existingTime.isAfter(now)) {
      return; // newer request already applied
    }

    // truy vấn các bài ghim khác ngay bây giờ (bên ngoài transaction)
    List<QueryDocumentSnapshot<Map<String, dynamic>>> otherPinnedDocs = [];
    if (pinned) {
      final otherSnap = await _postsCollection
          .where('authorId', isEqualTo: author)
          .where('isPinned', isEqualTo: true)
          .get();
      otherPinnedDocs = otherSnap.docs;
    }

    await FirebaseFirestore.instance.runTransaction((tx) async {
      // Lấy lại post trong transaction để đảm bảo nó vẫn tồn tại và
      // tránh vấn đề cập nhật bị mất.
      final txnPostSnap = await tx.get(postRef);
      if (!txnPostSnap.exists) return;

      if (pinned) {
        // bỏ ghim tất cả bài khác của tác giả này phòng trường hợp
        for (var doc in otherPinnedDocs) {
          if (doc.id != postId) {
            tx.update(doc.reference, {'isPinned': false});
          }
        }

        // ghim bài này
        tx.update(postRef, {'isPinned': true});
        tx.set(pinDocRef, {'pinnedPostId': postId, 'updatedAt': now});
      } else {
        // bỏ ghim bài này
        tx.update(postRef, {'isPinned': false});
        // cập nhật tài liệu userPins chỉ nếu chúng ta đang theo dõi bài này
        if (pinSnap.exists && pinSnap.data()?['pinnedPostId'] == postId) {
          tx.set(pinDocRef, {'pinnedPostId': null, 'updatedAt': now});
        }
      }
    });
  }

  // Chỉ cập nhật đối tượng bài viết
  Future<void> updatePostAudience(String postId, PostAudience audience) async {
    await _postsCollection.doc(postId).update({'audience': audience.name});
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    final post = await getPostById(postId);
    if (post == null) return;

    // Không cần xóa file media - chúng được lưu dưới dạng base64 trong Firestore
    // và sẽ bị xóa cùng với tài liệu bài viết

    // Xóa subcollection bình luận
    final comments = await _postsCollection
        .doc(postId)
        .collection('comments')
        .get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }

    // Xóa tài liệu bài viết
    await _postsCollection.doc(postId).delete();
  }

  // Thích bài viết
  Future<void> likePost(String postId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _postsCollection.doc(postId).update({
      'likes': FieldValue.arrayUnion([uid]),
      'likesCount': FieldValue.increment(1),
    });

    // thông báo cho tác giả
    try {
      final postSnap = await _postsCollection.doc(postId).get();
      final authorId = postSnap.data()?['authorId'] as String?;
      if (authorId != null && authorId != uid) {
        await FirebaseNotificationService().sendNotification(
          recipientId: authorId,
          message: 'đã thích bài viết của bạn.',
          type: NotificationType.like,
          extraData: {'postId': postId},
        );
      }
    } catch (e) {
      print('like notification error: $e');
    }
  }

  // Bỏ thích bài viết
  Future<void> unlikePost(String postId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _postsCollection.doc(postId).update({
      'likes': FieldValue.arrayRemove([uid]),
      'likesCount': FieldValue.increment(-1),
    });
  }

  // Kiểm tra đã thích
  Future<bool> isPostLiked(String postId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final doc = await _postsCollection.doc(postId).get();
    final likes = List<String>.from(doc.data()?['likes'] ?? []);
    return likes.contains(uid);
  }

  // Thêm bình luận
  Future<CommentModel?> addComment({
    required String postId,
    required String content,
    required String authorName,
    String? authorPhotoUrl,
    String? parentCommentId,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final commentsCollection = _postsCollection
        .doc(postId)
        .collection('comments');
    final docRef = commentsCollection.doc();

    final comment = CommentModel(
      id: docRef.id,
      postId: postId,
      authorId: uid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      parentCommentId: parentCommentId,
      createdAt: DateTime.now(),
    );

    await docRef.set(comment.toFirestore());

    // Cập nhật số bình luận trên bài viết
    await _postsCollection.doc(postId).update({
      'commentCount': FieldValue.increment(1),
      'commentsCount': FieldValue.increment(1),
    });

    // thông báo cho tác giả
    try {
      final postSnap = await _postsCollection.doc(postId).get();
      final authorId = postSnap.data()?['authorId'] as String?;
      if (authorId != null && authorId != uid) {
        await FirebaseNotificationService().sendNotification(
          recipientId: authorId,
          message: 'đã bình luận về bài viết của bạn.',
          type: NotificationType.comment,
          extraData: {'postId': postId},
        );
      }
    } catch (e) {
      print('comment notification error: $e');
    }

    return comment;
  }

  // Lấy bình luận cho bài viết
  Stream<List<CommentModel>> getComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete comment
  Future<void> deleteComment(String postId, String commentId) async {
    await _postsCollection
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    await _postsCollection.doc(postId).update({
      'commentCount': FieldValue.increment(-1),
      'commentsCount': FieldValue.increment(-1),
    });
  }

  // Thích bình luận
  Future<void> likeComment(String postId, String commentId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _postsCollection
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
          'likes': FieldValue.arrayUnion([uid]),
          'likesCount': FieldValue.increment(1),
        });
  }

  // Bỏ thích bình luận
  Future<void> unlikeComment(String postId, String commentId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _postsCollection
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
          'likes': FieldValue.arrayRemove([uid]),
          'likesCount': FieldValue.increment(-1),
        });
  }

  // Lấy feed (bài viết từ người theo dõi + bài của chính mình)
  // Lọc ở phía client để tránh yêu cầu chỉ mục ghép
  Stream<List<PostModel>> getFeed(List<String> followingIds) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final allIds = {...followingIds, uid}.toList();

    return _postsCollection
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .where(
                (post) =>
                    allIds.contains(post.authorId) &&
                    post.audience == PostAudience.public,
              )
              .take(50)
              .toList();
          return posts;
        });
  }

  // Lấy feed công khai (tất cả bài công khai)
  // Lưu ý: truy vấn không dùng chỉ mục ghép - lọc ở client cho đơn giản.
  // Chúng ta cũng loại bỏ bất kỳ bài nào do người dùng hiện tại đã chặn.
  Stream<List<PostModel>> getPublicFeed({int limit = 20}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _postsCollection
        .orderBy('createdAt', descending: true)
        .limit(100) // Tránh lỗi Firestore Web SDK do các query limit khác nhau
        .snapshots()
        .asyncMap((snapshot) async {
          final blocked = await _getBlockedUsers();
          final posts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .where(
                (post) =>
                    post.audience == PostAudience.public &&
                    !blocked.contains(post.authorId),
              )
              .take(limit)
              .toList();
          return posts;
        })
        .handleError((error) {
          print('Error loading public feed: $error');
          return <PostModel>[];
        });
  }

  /// Trả về các bài viết nơi mảng `hashtags` (lưu trên tài liệu)
  /// chứa chuỗi hashtag đã cho.
  Stream<List<PostModel>> getPostsByHashtag(String hashtag, {int limit = 50}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _postsCollection
        .where('hashtags', arrayContains: hashtag)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
          final blocked = await _getBlockedUsers();
          final posts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .where(
                (post) =>
                    post.audience == PostAudience.public &&
                    !blocked.contains(post.authorId),
              )
              .take(limit)
              .toList();
          return posts;
        })
        .handleError((error) {
          print('Error in getPostsByHashtag: $error');
          return <PostModel>[];
        });
  }

  // Lấy bài của người dùng - query trực tiếp theo authorId.
  // Yêu cầu composite index (authorId, createdAt) trong Firestore.
  Stream<List<PostModel>> getUserPosts(String userId, {int limit = 50}) {
    final uid = currentUserId;

    return _postsCollection
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
          final blocked = await _getBlockedUsers();
          final posts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .where((post) {
                if (blocked.contains(post.authorId)) return false;
                if (userId == uid) return true;
                return post.audience == PostAudience.public;
              })
              .toList();

          // đảm bảo bài ghim có mặt ngay cả khi cũ hơn giới hạn
          try {
            final pinSnap = await FirebaseFirestore.instance
                .collection('userPins')
                .doc(userId)
                .get();
            if (pinSnap.exists) {
              final pinnedId = pinSnap.data()?['pinnedPostId'] as String?;
              if (pinnedId != null && !posts.any((p) => p.id == pinnedId)) {
                final pSnap = await _postsCollection.doc(pinnedId).get();
                if (pSnap.exists) {
                  final pinnedPost = PostModel.fromFirestore(pSnap);
                  // chỉ hiển thị bài ghim nếu là bài của chính user này
                  if (pinnedPost.authorId == userId) {
                    if (!blocked.contains(pinnedPost.authorId)) {
                      posts.insert(0, pinnedPost);
                    }
                  }
                }
              }
            }
          } catch (e) {
            // bỏ qua lỗi khi fetch bài ghim - feed vẫn dùng được
          }

          // sắp xếp lại để ghim trước rồi mới đến mới nhất
          posts.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

          return posts;
        })
        .handleError((error) {
          print('Error in getUserPosts: $error');
          return <PostModel>[];
        });
  }

  // Luồng một bài viết
  Stream<PostModel?> streamPost(String postId) {
    return _postsCollection
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists ? PostModel.fromFirestore(doc) : null);
  }

  // Chia sẻ bài viết
  Future<void> sharePost(String postId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _postsCollection.doc(postId).update({
      'sharesCount': FieldValue.increment(1),
      'sharedBy': FieldValue.arrayUnion([uid]),
    });

    // thông báo cho tác giả
    try {
      final postSnap = await _postsCollection.doc(postId).get();
      final authorId = postSnap.data()?['authorId'] as String?;
      if (authorId != null && authorId != uid) {
        await FirebaseNotificationService().sendNotification(
          recipientId: authorId,
          message: 'đã chia sẻ bài viết của bạn.',
          type: NotificationType.share,
          extraData: {'postId': postId},
        );
      }
    } catch (e) {
      print('share notification error: $e');
    }
  }

  /// Tạo bài viết chia sẻ (shared post) - giống Facebook
  /// Tạo một bài viết mới với bài viết gốc được nhúng bên trong
  Future<PostModel?> createSharedPost({
    required String originalPostId,
    required String authorName,
    String? authorPhotoUrl,
    String content = '', // Caption của người chia sẻ
    PostAudience audience = PostAudience.public,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    // Lấy thông tin bài viết gốc
    final originalPost = await getPostById(originalPostId);
    if (originalPost == null) {
      print('Original post not found: $originalPostId');
      return null;
    }

    // Tạo dữ liệu bài viết gốc để nhúng
    final sharedPostData = {
      'id': originalPost.id,
      'authorId': originalPost.authorId,
      'authorName': originalPost.authorName,
      'authorPhotoUrl': originalPost.authorPhotoUrl,
      'content': originalPost.content,
      'mediaUrls': originalPost.mediaUrls,
      'backgroundColor': originalPost.backgroundColor,
      'createdAt': originalPost.createdAt.toIso8601String(),
      'layoutIndex': originalPost.layoutIndex,
      'location': originalPost.location,
      'hashtags': originalPost.hashtags,
    };

    // Tạo bài viết chia sẻ mới
    final docRef = _postsCollection.doc();
    final postId = docRef.id;

    final sharedPost = PostModel(
      id: postId,
      authorId: uid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content, // Caption của người chia sẻ
      mediaUrls: [], // Bài chia sẻ không có media riêng
      audience: audience,
      createdAt: DateTime.now(),
      isPinned: false,
      allowComments: true,
      albumIds: [],
      layoutIndex: 0,
      sharedPostId: originalPostId,
      sharedPostData: sharedPostData,
    );

    await docRef.set(sharedPost.toFirestore());

    // Cập nhật share count và sharedBy của bài viết gốc
    await _postsCollection.doc(originalPostId).update({
      'shareCount': FieldValue.increment(1),
      'sharedBy': FieldValue.arrayUnion([uid]),
    });

    // Gửi thông báo cho tác giả bài viết gốc
    if (originalPost.authorId != uid) {
      try {
        await FirebaseNotificationService().sendNotification(
          recipientId: originalPost.authorId,
          message: '$authorName đã chia sẻ bài viết của bạn.',
          type: NotificationType.share,
          senderName: authorName,
          senderPhotoUrl: authorPhotoUrl,
          extraData: {'postId': postId, 'originalPostId': originalPostId},
        );
      } catch (e) {
        print('Error sending share notification: $e');
      }
    }

    return sharedPost;
  }

  // Tìm kiếm bài viết - lọc ở client để tránh yêu cầu chỉ mục
  Future<List<PostModel>> searchPosts(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot = await _postsCollection
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final posts = snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .where(
          (post) =>
              post.audience == PostAudience.public &&
              (post.content.toLowerCase().contains(queryLower) ||
                  post.authorName.toLowerCase().contains(queryLower) ||
                  post.hashtags.any(
                    (tag) => tag.toLowerCase().contains(queryLower),
                  )),
        )
        .take(50)
        .toList();

    return posts;
  }
}
