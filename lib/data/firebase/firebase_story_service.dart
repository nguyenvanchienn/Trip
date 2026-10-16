import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:tourn/models/story_model.dart';

class FirebaseStoryService {
  // Singleton pattern
  static final FirebaseStoryService _instance =
      FirebaseStoryService._internal();
  factory FirebaseStoryService() => _instance;
  FirebaseStoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _storiesCollection =>
      _firestore.collection('stories');

  String? get currentUserId => _auth.currentUser?.uid;

  // Compress image to reduce size for Firestore storage
  Uint8List _compressImage(
    Uint8List bytes, {
    int maxWidth = 800,
    int quality = 70,
  }) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Resize if too large
      img.Image resized;
      if (image.width > maxWidth) {
        resized = img.copyResize(image, width: maxWidth);
      } else {
        resized = image;
      }

      // Encode as JPEG with compression
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      print('Error compressing image: $e');
      return bytes;
    }
  }

  // Convert image file to base64 data URL
  Future<String?> _imageToBase64(String filePath) async {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        print('Error: File does not exist at path: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      print('Read ${bytes.length} bytes from file');

      // Compress the image
      final compressedBytes = _compressImage(bytes);
      print('Compressed size: ${compressedBytes.length} bytes');

      // Convert to base64 data URL
      final base64String = base64Encode(compressedBytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';

      print('Base64 URL length: ${dataUrl.length} chars');
      return dataUrl;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  // Upload video to Firebase Storage and return URL
  Future<String?> _uploadVideoToStorage(String filePath, String storyId) async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;

      final file = File(filePath);
      if (!await file.exists()) {
        print('Error: Video file does not exist at path: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      print('Video size: ${bytes.length} bytes');

      final ref = _storage.ref().child('stories/$uid/$storyId/video.mp4');
      final uploadTask = await ref.putData(
        bytes,
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

  // Create a new story (using base64 for images like posts)
  Future<StoryModel?> createStory({
    required String filePath,
    required StoryType type,
    required String authorName,
    String? authorPhotoUrl,
    String? caption,
    String? location,
    String? country,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('Chưa đăng nhập');
    }

    final docRef = _storiesCollection.doc();
    final storyId = docRef.id;

    String? mediaUrl;

    // For images, use base64 (like posts)
    // For videos, we skip for now (would need Firebase Storage)
    if (type == StoryType.image) {
      mediaUrl = await _imageToBase64(filePath);
    } else {
      // Upload video to Firebase Storage
      mediaUrl = await _uploadVideoToStorage(filePath, storyId);
    }

    if (mediaUrl == null) {
      throw Exception('Không thể xử lý file media');
    }

    final now = DateTime.now();
    final story = StoryModel(
      id: storyId,
      authorId: uid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      mediaUrl: mediaUrl,
      type: type,
      caption: caption,
      location: location,
      country: country,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      likes: [],
      viewers: [],
      commentCount: 0,
      isLive: false,
    );

    await docRef.set(story.toFirestore());
    return story;
  }

  // Create a live story
  Future<StoryModel?> createLiveStory({
    required String authorName,
    String? authorPhotoUrl,
    String? location,
    String? country,
    String? liveStreamId,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final docRef = _storiesCollection.doc();
      final now = DateTime.now();

      final story = StoryModel(
        id: docRef.id,
        authorId: uid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        mediaUrl: '', // Live streams don't have a media URL initially
        type: StoryType.live,
        location: location,
        country: country,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        likes: [],
        viewers: [],
        commentCount: 0,
        isLive: true,
        liveStreamId: liveStreamId,
      );

      await docRef.set(story.toFirestore());
      return story;
    } catch (e) {
      print('Error creating live story: $e');
      return null;
    }
  }

  // End live stream
  Future<void> endLiveStream(String storyId) async {
    try {
      await _storiesCollection.doc(storyId).update({'isLive': false});
    } catch (e) {
      print('Error ending live stream: $e');
    }
  }

  // Get stories from friends (users the current user follows)
  Stream<List<StoryModel>> getFriendsStories(List<String> followingIds) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final allIds = {...followingIds, uid}.toList();
    final now = DateTime.now();

    return _storiesCollection
        .where('authorId', whereIn: allIds.take(10).toList()) // Firestore limit
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .where((story) => !story.isExpired)
              .toList();
        });
  }

  // Get all active stories (for explore/discovery)
  Stream<List<StoryModel>> getPublicStories({int limit = 20}) {
    final now = DateTime.now();

    // Simplified query - just filter by expiresAt to avoid index issues
    return _storiesCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          print('Stories snapshot: ${snapshot.docs.length} documents');
          return snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .where((story) => !story.isExpired) // Filter expired client-side
              .toList();
        })
        .handleError((error) {
          print('Error loading stories: $error');
          return <StoryModel>[];
        });
  }

  // Get stories by user
  Stream<List<StoryModel>> getUserStories(String userId) {
    return _storiesCollection
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .where((story) => !story.isExpired) // Filter expired client-side
              .toList();
        })
        .handleError((error) {
          print('Error loading user stories: $error');
          return <StoryModel>[];
        });
  }

  // Get current user's stories
  Stream<List<StoryModel>> getMyStories() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return getUserStories(uid);
  }

  // Get live stories
  Stream<List<StoryModel>> getLiveStories() {
    return _storiesCollection
        .where('isLive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .toList();
        });
  }

  // Like a story
  Future<void> likeStory(String storyId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _storiesCollection.doc(storyId).update({
      'likes': FieldValue.arrayUnion([uid]),
    });
  }

  // Unlike a story
  Future<void> unlikeStory(String storyId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _storiesCollection.doc(storyId).update({
      'likes': FieldValue.arrayRemove([uid]),
    });
  }

  // Mark story as viewed
  Future<void> markAsViewed(String storyId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _storiesCollection.doc(storyId).update({
      'viewers': FieldValue.arrayUnion([uid]),
    });
  }

  // Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      // Delete story document (media is stored as base64 in Firestore, no separate file to delete)
      await _storiesCollection.doc(storyId).delete();
    } catch (e) {
      print('Error deleting story: $e');
    }
  }

  // Get story by ID
  Future<StoryModel?> getStoryById(String storyId) async {
    try {
      final doc = await _storiesCollection.doc(storyId).get();
      if (doc.exists) {
        return StoryModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting story: $e');
    }
    return null;
  }

  // Clean up expired stories (can be called periodically or via Cloud Function)
  // Archives video stories to profile_videos before deleting
  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now();
      final snapshot = await _storiesCollection
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in snapshot.docs) {
        final story = StoryModel.fromFirestore(doc);

        // Archive video stories to profile_videos collection
        if (story.type == StoryType.video) {
          await archiveVideoStoryToProfile(story);
        }

        await deleteStory(doc.id);
      }
    } catch (e) {
      print('Error cleaning up expired stories: $e');
    }
  }

  // Archive a video story to the user's profile videos
  Future<void> archiveVideoStoryToProfile(StoryModel story) async {
    try {
      if (story.type != StoryType.video) return;

      final profileVideosCollection = _firestore.collection('profile_videos');

      // Check if already archived
      final existing = await profileVideosCollection
          .where('originalStoryId', isEqualTo: story.id)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Story ${story.id} already archived');
        return;
      }

      // Create profile video document
      await profileVideosCollection.add({
        'authorId': story.authorId,
        'authorName': story.authorName,
        'authorPhotoUrl': story.authorPhotoUrl,
        'mediaUrl': story.mediaUrl,
        'caption': story.caption,
        'location': story.location,
        'country': story.country,
        'createdAt': Timestamp.fromDate(story.createdAt),
        'archivedAt': Timestamp.fromDate(DateTime.now()),
        'likes': story.likes.length,
        'views': story.viewers.length,
        'thumbnailUrl': null, // Could generate thumbnail if needed
        'originalStoryId': story.id,
      });

      print('Archived video story ${story.id} to profile_videos');
    } catch (e) {
      print('Error archiving video story: $e');
    }
  }

  // Get archived videos for a user
  Stream<List<Map<String, dynamic>>> getArchivedVideos(String userId) {
    return _firestore
        .collection('profile_videos')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Manually archive a video story (called when story is about to expire)
  Future<void> archiveMyVideoStory(String storyId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final story = await getStoryById(storyId);
    if (story != null &&
        story.authorId == uid &&
        story.type == StoryType.video) {
      await archiveVideoStoryToProfile(story);
    }
  }

  // ==================== STORY COMMENTS ====================

  // Add comment to story
  Future<Map<String, dynamic>?> addStoryComment({
    required String storyId,
    required String content,
    required String authorName,
    String? authorPhotoUrl,
    String? parentCommentId,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final commentsCollection = _storiesCollection
        .doc(storyId)
        .collection('comments');
    final docRef = commentsCollection.doc();

    final commentData = {
      'id': docRef.id,
      'storyId': storyId,
      'authorId': uid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'likes': <String>[],
      'parentCommentId': parentCommentId,
      'replyCount': 0,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };

    await docRef.set(commentData);

    // Update comment count on story
    await _storiesCollection.doc(storyId).update({
      'commentCount': FieldValue.increment(1),
    });

    // If it's a reply, update parent's reply count
    if (parentCommentId != null) {
      await commentsCollection.doc(parentCommentId).update({
        'replyCount': FieldValue.increment(1),
      });
    }

    return {...commentData, 'id': docRef.id};
  }

  // Get comments for story
  Stream<List<Map<String, dynamic>>> getStoryComments(String storyId) {
    return _storiesCollection
        .doc(storyId)
        .collection('comments')
        .where('parentCommentId', isNull: true) // Only top-level comments
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // Get replies for a comment
  Stream<List<Map<String, dynamic>>> getCommentReplies(
    String storyId,
    String commentId,
  ) {
    return _storiesCollection
        .doc(storyId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: commentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // Delete comment
  Future<void> deleteStoryComment(String storyId, String commentId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final commentDoc = await _storiesCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (!commentDoc.exists) return;

    final commentData = commentDoc.data()!;

    // Only author can delete their comment
    if (commentData['authorId'] != uid) return;

    final parentId = commentData['parentCommentId'] as String?;

    await _storiesCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .delete();

    // Update story comment count
    await _storiesCollection.doc(storyId).update({
      'commentCount': FieldValue.increment(-1),
    });

    // If it was a reply, update parent's reply count
    if (parentId != null) {
      await _storiesCollection
          .doc(storyId)
          .collection('comments')
          .doc(parentId)
          .update({'replyCount': FieldValue.increment(-1)});
    }
  }

  // Edit comment
  Future<void> editStoryComment(
    String storyId,
    String commentId,
    String newContent,
  ) async {
    final uid = currentUserId;
    if (uid == null) return;

    final commentDoc = await _storiesCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (!commentDoc.exists) return;

    final commentData = commentDoc.data()!;
    if (commentData['authorId'] != uid) return;

    await _storiesCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .update({
          'content': newContent,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
  }

  // Like comment
  Future<void> likeStoryComment(String storyId, String commentId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _storiesCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .update({
          'likes': FieldValue.arrayUnion([uid]),
        });
  }

  // Unlike comment
  Future<void> unlikeStoryComment(String storyId, String commentId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _storiesCollection
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .update({
          'likes': FieldValue.arrayRemove([uid]),
        });
  }
}
