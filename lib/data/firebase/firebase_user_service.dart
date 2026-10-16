import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../../models/user_model.dart';
import '../../models/notification_model.dart';
import 'firebase_notification_service.dart';

class FirebaseUserService {
  // Singleton pattern
  static final FirebaseUserService _instance = FirebaseUserService._internal();
  factory FirebaseUserService() => _instance;
  FirebaseUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Random _random = Random();

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Generate default username from displayName + random numbers
  String _generateUsername(String displayName) {
    // Remove Vietnamese diacritics and special characters
    final normalized = _removeDiacritics(
      displayName.toLowerCase(),
    ).replaceAll(RegExp(r'[^a-z0-9]'), '');
    final base = normalized.isEmpty ? 'user' : normalized;
    final randomNum = _random.nextInt(900000) + 100000; // 6 digit random
    return '$base$randomNum';
  }

  // Remove Vietnamese diacritics
  String _removeDiacritics(String str) {
    const vietnamese =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const ascii =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (int i = 0; i < vietnamese.length; i++) {
      str = str.replaceAll(vietnamese[i], ascii[i]);
    }
    return str;
  }

  // Create user in Firestore after registration
  Future<void> createUser(User firebaseUser, {String? displayName}) async {
    print('[UserService] createUser called for ${firebaseUser.uid}');
    await _waitForAuthUser(firebaseUser.uid);
    await _auth.currentUser?.getIdToken(true);
    final name = displayName ?? firebaseUser.displayName ?? 'User';
    // Username defaults to uid (can be changed later)
    final username = firebaseUser.uid;

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: name,
      username: username,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isOnline: true,
    );

    print('[UserService] Calling Firestore set()...');
    await _setUserWithRetry(firebaseUser.uid, userModel.toFirestore());
    print('[UserService] Firestore set() completed');
  }

  Future<void> _waitForAuthUser(String uid) async {
    final current = _auth.currentUser;
    if (current?.uid == uid) return;

    await _auth.authStateChanges().firstWhere((user) => user?.uid == uid);
  }

  Future<void> _setUserWithRetry(String uid, Map<String, dynamic> data) async {
    FirebaseException? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _usersCollection.doc(uid).set(data);
        return;
      } on FirebaseException catch (e) {
        lastError = e;
        final authReady = _auth.currentUser?.uid == uid;
        final isPermission = e.code == 'permission-denied';
        if (!isPermission || authReady) {
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 400));
        await _auth.currentUser?.getIdToken(true);
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  // Get username of current user (use uid if missing for old accounts)
  Future<String?> getUsername() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _usersCollection.doc(uid).get();
      final data = doc.data();
      if (data == null) return uid; // Return uid if no data

      // If username exists, return it
      final existingUsername = data['username'] as String?;
      if (existingUsername != null && existingUsername.isNotEmpty) {
        return existingUsername;
      }

      // Set username to uid for old accounts
      await _usersCollection.doc(uid).update({'username': uid});
      return uid;
    } catch (e) {
      print('Error getting username: $e');
      return uid; // Fallback to uid on error
    }
  }

  // Update username (only allowed once every 7 days)
  Future<({bool success, int? daysRemaining})> updateUsername(
    String newUsername,
  ) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, daysRemaining: null);

    // Get current user data to check last change time
    final doc = await _usersCollection.doc(uid).get();
    final data = doc.data();
    if (data != null) {
      final lastChange = (data['lastUsernameChange'] as Timestamp?)?.toDate();
      if (lastChange != null) {
        final daysSinceChange = DateTime.now().difference(lastChange).inDays;
        if (daysSinceChange < 7) {
          return (success: false, daysRemaining: 7 - daysSinceChange);
        }
      }
    }

    // Check if username is already taken
    final existing = await _usersCollection
        .where('username', isEqualTo: newUsername)
        .get();

    if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
      return (success: false, daysRemaining: null); // Username already taken
    }

    await _usersCollection.doc(uid).update({
      'username': newUsername,
      'lastUsernameChange': Timestamp.fromDate(DateTime.now()),
    });
    return (success: true, daysRemaining: null);
  }

  // Get days remaining until username can be changed
  Future<int?> getDaysUntilUsernameChange() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _usersCollection.doc(uid).get();
    final data = doc.data();
    if (data == null) return 0; // Can change now

    final lastChange = (data['lastUsernameChange'] as Timestamp?)?.toDate();
    if (lastChange == null) return 0; // Never changed, can change now

    final daysSinceChange = DateTime.now().difference(lastChange).inDays;
    if (daysSinceChange >= 7) return 0; // Can change now
    return 7 - daysSinceChange;
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final uid = currentUserId;
    final existing = await _usersCollection
        .where('username', isEqualTo: username)
        .get();

    if (existing.docs.isEmpty) return true;
    // Available if it belongs to current user
    return existing.docs.first.id == uid;
  }

  // Get user by ID (auto-generates username if missing)
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      final user = UserModel.fromFirestore(doc);
      // Auto-generate username for old accounts
      if (user.username == null || user.username!.isEmpty) {
        final newUsername = uid; // Use uid as default username
        await _usersCollection.doc(uid).update({'username': newUsername});
        return user.copyWith(username: newUsername);
      }
      return user;
    }
    return null;
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return getUserById(uid);
  }

  // Update user profile
  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.uid).update(user.toFirestore());
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({'displayName': displayName});
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // Update bio
  Future<void> updateBio(String bio) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({'bio': bio});
  }

  // Compress image to reduce size for Firestore storage
  Uint8List _compressImage(
    Uint8List bytes, {
    int maxWidth = 400,
    int quality = 60,
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

  // Upload and update profile photo (using base64 in Firestore)
  Future<String?> updateProfilePhoto(File imageFile) async {
    final uid = currentUserId;
    if (uid == null) {
      print('updateProfilePhoto: uid is null');
      return null;
    }

    try {
      print('updateProfilePhoto: converting to base64');
      final base64Url = await _imageToBase64(imageFile.path);

      if (base64Url == null) {
        print('updateProfilePhoto: failed to convert to base64');
        return null;
      }

      print('updateProfilePhoto: saving to Firestore');
      await _usersCollection.doc(uid).update({'photoUrl': base64Url});
      print('updateProfilePhoto: saved successfully');

      return base64Url;
    } catch (e, stackTrace) {
      print('Error uploading profile photo: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      await _usersCollection.doc(uid).update({'photoUrl': null});
      return true;
    } catch (e) {
      print('Error deleting profile photo: $e');
      return false;
    }
  }

  // Update online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = currentUserId;
    if (uid == null) return;

    print('[UserService] setOnlineStatus($isOnline) called for uid: $uid');
    try {
      if (_auth.currentUser?.uid != uid) return;
      // Use set with merge to avoid error if document doesn't exist yet
      await _usersCollection.doc(uid).set({
        'isOnline': isOnline,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
      print('[UserService] setOnlineStatus completed');
    } catch (e) {
      print('[UserService] setOnlineStatus ERROR: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  // Follow user
  Future<void> followUser(
    String targetUserId, {
    bool ignorePrivacy = false,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    if (!ignorePrivacy) {
      final isPrivate = await isPrivateAccount(targetUserId);
      if (isPrivate) {
        await requestFollow(targetUserId);
        return;
      }
    }

    final batch = _firestore.batch();

    // Add to current user's following
    batch.update(_usersCollection.doc(uid), {
      'following': FieldValue.arrayUnion([targetUserId]),
      'followingCount': FieldValue.increment(1),
    });

    // Add to target user's followers
    batch.update(_usersCollection.doc(targetUserId), {
      'followers': FieldValue.arrayUnion([uid]),
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();

    // send notification to the followed user
    try {
      if (uid != targetUserId) {
        await FirebaseNotificationService().sendNotification(
          recipientId: targetUserId,
          message: 'đã bắt đầu theo dõi bạn.',
          type: NotificationType.follow,
        );
      }
    } catch (e) {
      print('follow notification error: $e');
    }
  }

  Future<bool> isPrivateAccount(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.data()?['isPrivate'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestFollow(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;
    if (uid == targetUserId) return;

    final batch = _firestore.batch();
    batch.update(_usersCollection.doc(targetUserId), {
      'followRequests': FieldValue.arrayUnion([uid]),
    });
    batch.update(_usersCollection.doc(uid), {
      'followRequested': FieldValue.arrayUnion([targetUserId]),
    });
    await batch.commit();

    try {
      await FirebaseNotificationService().sendNotification(
        recipientId: targetUserId,
        message: 'đã gửi yêu cầu theo dõi bạn.',
        type: NotificationType.followRequest,
      );
    } catch (e) {
      print('follow request notification error: $e');
    }
  }

  Future<void> cancelFollowRequest(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;
    if (uid == targetUserId) return;

    final batch = _firestore.batch();
    batch.update(_usersCollection.doc(targetUserId), {
      'followRequests': FieldValue.arrayRemove([uid]),
    });
    batch.update(_usersCollection.doc(uid), {
      'followRequested': FieldValue.arrayRemove([targetUserId]),
    });
    await batch.commit();
  }

  Future<void> acceptFollowRequest(String requesterId) async {
    final uid = currentUserId;
    if (uid == null) return;
    if (uid == requesterId) return;

    final batch = _firestore.batch();

    // Remove pending request
    batch.update(_usersCollection.doc(uid), {
      'followRequests': FieldValue.arrayRemove([requesterId]),
    });
    batch.update(_usersCollection.doc(requesterId), {
      'followRequested': FieldValue.arrayRemove([uid]),
    });

    // Add as approved follower/following
    batch.update(_usersCollection.doc(uid), {
      'followers': FieldValue.arrayUnion([requesterId]),
      'followersCount': FieldValue.increment(1),
    });
    batch.update(_usersCollection.doc(requesterId), {
      'following': FieldValue.arrayUnion([uid]),
      'followingCount': FieldValue.increment(1),
    });

    await batch.commit();

    try {
      await FirebaseNotificationService().sendNotification(
        recipientId: requesterId,
        message: 'đã chấp nhận yêu cầu theo dõi của bạn.',
        type: NotificationType.follow,
      );
    } catch (e) {
      print('follow accept notification error: $e');
    }

    try {
      final requesterDoc = await _usersCollection.doc(requesterId).get();
      final requesterData = requesterDoc.data() ?? {};
      final requesterName = requesterData['displayName'] as String? ?? '';
      final requesterPhoto = requesterData['photoUrl'] as String?;
      await FirebaseNotificationService().sendNotification(
        recipientId: uid,
        message: 'đã theo dõi bạn.',
        type: NotificationType.follow,
        senderId: requesterId,
        senderName: requesterName,
        senderPhotoUrl: requesterPhoto,
      );
    } catch (e) {
      print('follow accept self notification error: $e');
    }
  }

  Future<void> declineFollowRequest(String requesterId) async {
    final uid = currentUserId;
    if (uid == null) return;
    if (uid == requesterId) return;

    final batch = _firestore.batch();
    batch.update(_usersCollection.doc(uid), {
      'followRequests': FieldValue.arrayRemove([requesterId]),
    });
    batch.update(_usersCollection.doc(requesterId), {
      'followRequested': FieldValue.arrayRemove([uid]),
    });
    await batch.commit();
  }

  Future<bool> isFollowRequested(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    if (uid == targetUserId) return false;

    try {
      final doc = await _usersCollection.doc(uid).get();
      final requested = List<String>.from(doc.data()?['followRequested'] ?? []);
      return requested.contains(targetUserId);
    } catch (_) {
      return false;
    }
  }

  Stream<List<UserModel>> getFollowRequests(String userId) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<UserModel>[]);
      return _usersCollection
          .doc(userId)
          .snapshots()
          .handleError((_) {})
          .asyncMap((snap) async {
            final data = snap.data();
            final ids = List<String>.from(data?['followRequests'] ?? []);
            if (ids.isEmpty) return <UserModel>[];
            final futures = ids.map((id) => getUserById(id)).toList();
            final users = await Future.wait(futures);
            return users.whereType<UserModel>().toList();
          });
    });
  }

  // Unfollow user
  Future<void> unfollowUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final batch = _firestore.batch();

    // Remove from current user's following
    batch.update(_usersCollection.doc(uid), {
      'following': FieldValue.arrayRemove([targetUserId]),
      'followingCount': FieldValue.increment(-1),
    });

    // Remove from target user's followers
    batch.update(_usersCollection.doc(targetUserId), {
      'followers': FieldValue.arrayRemove([uid]),
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Remove a follower (someone who follows you)
  Future<void> removeFollower(String followerUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final batch = _firestore.batch();

    // Remove from current user's followers
    batch.update(_usersCollection.doc(uid), {
      'followers': FieldValue.arrayRemove([followerUserId]),
      'followersCount': FieldValue.increment(-1),
    });

    // Remove current user from follower's following list
    batch.update(_usersCollection.doc(followerUserId), {
      'following': FieldValue.arrayRemove([uid]),
      'followingCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Unfriend user (remove both follow relationships)
  Future<void> unfriendUser(String userId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final batch = _firestore.batch();

    // Update current user: remove from both following and followers
    batch.update(_usersCollection.doc(uid), {
      'following': FieldValue.arrayRemove([userId]),
      'followingCount': FieldValue.increment(-1),
      'followers': FieldValue.arrayRemove([userId]),
      'followersCount': FieldValue.increment(-1),
    });

    // Update target user: remove current user from both followers and following
    batch.update(_usersCollection.doc(userId), {
      'followers': FieldValue.arrayRemove([uid]),
      'followersCount': FieldValue.increment(-1),
      'following': FieldValue.arrayRemove([uid]),
      'followingCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Check if following
  Future<bool> isFollowing(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final doc = await _usersCollection.doc(uid).get();
    final following = List<String>.from(doc.data()?['following'] ?? []);
    return following.contains(targetUserId);
  }

  /// Checks if [userId] follows the current user by reading that user's
  /// document and inspecting their `following` array.
  Future<bool> isFollowingMe(String userId) async {
    final me = currentUserId;
    if (me == null) return false;
    final doc = await _usersCollection.doc(userId).get();
    final following = List<String>.from(doc.data()?['following'] ?? []);
    return following.contains(me);
  }

  // Check if a user is restricted by the current user
  Future<bool> isRestricted(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final doc = await _usersCollection.doc(uid).get();
    final restricted = List<String>.from(doc.data()?['restricted'] ?? []);
    return restricted.contains(targetUserId);
  }

  // Check whether the current user has been restricted by [otherUserId].
  // This looks up the other user's document and inspects their
  // `restricted` array for our UID.  It is useful when we need to hide
  // sensitive information (like online status) from someone who has
  // chosen to restrict us.
  Future<bool> isRestrictedBy(String otherUserId) async {
    final me = currentUserId;
    if (me == null) return false;

    final doc = await _usersCollection.doc(otherUserId).get();
    final restricted = List<String>.from(doc.data()?['restricted'] ?? []);
    return restricted.contains(me);
  }

  // Add another user to the restricted list
  Future<void> restrictUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({
      'restricted': FieldValue.arrayUnion([targetUserId]),
    });
  }

  // Remove a user from restricted list
  Future<void> unrestrictUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _usersCollection.doc(uid).update({
      'restricted': FieldValue.arrayRemove([targetUserId]),
    });
  }

  // Stream restricted user documents
  Stream<List<UserModel>> getRestrictedUsers() {
    return _auth.authStateChanges().asyncExpand((user) {
      final uid = user?.uid;
      if (uid == null) return Stream.value(<UserModel>[]);

      return _usersCollection.doc(uid).snapshots().handleError((_) {}).asyncMap(
        (doc) async {
          final data = doc.data();
          if (data == null) return <UserModel>[];
          final restricted = List<String>.from(data['restricted'] ?? []);
          if (restricted.isEmpty) return <UserModel>[];
          final futures = restricted.map((id) => getUserById(id));
          final list = await Future.wait(futures);
          return list.whereType<UserModel>().toList();
        },
      );
    });
  }

  // Check if a user is blocked by the current user
  Future<bool> isBlocked(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final doc = await _usersCollection.doc(uid).get();
    final blocked = List<String>.from(doc.data()?['blocked'] ?? []);
    return blocked.contains(targetUserId);
  }

  /// Returns `true` if *the other user* has blocked the current user.
  ///
  /// This is implemented by reading the `blocked` array from the other
  /// user's document and checking for our own UID.  Having a dedicated
  /// helper makes calling code easier to read and mirrors `isRestrictedBy`.
  Future<bool> isBlockedBy(String otherUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final doc = await _usersCollection.doc(otherUserId).get();
    final blocked = List<String>.from(doc.data()?['blocked'] ?? []);
    return blocked.contains(uid);
  }

  // Add another user to the blocked list.  Also sever any follow relationship
  // so that blocked accounts immediately disappear from your follower/following lists.
  Future<void> blockUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;

    // remove any existing follow relationships in both directions using
    // the helper methods that have the correct security rules.
    // if the user was following us, drop that first
    await removeFollower(targetUserId);
    // if we were following them, unfollow
    await unfollowUser(targetUserId);

    // now mark them blocked; we don't need to update follower/following
    // again because the two helpers above already cleaned them up.
    await _usersCollection.doc(uid).update({
      'blocked': FieldValue.arrayUnion([targetUserId]),
    });
  }

  // Remove a user from blocked list.  We intentionally **do not** re-follow
  // or re-add any follower relationships.  Unblocking simply clears the
  // flag; the user will need to be followed again manually.
  Future<void> unblockUser(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _usersCollection.doc(uid).update({
      'blocked': FieldValue.arrayRemove([targetUserId]),
    });
  }

  // Stream blocked users in the current user's list
  Stream<List<UserModel>> getBlockedUsers() {
    return _auth.authStateChanges().asyncExpand((user) {
      final uid = user?.uid;
      if (uid == null) return Stream.value(<UserModel>[]);
      return _usersCollection.doc(uid).snapshots().handleError((_) {}).asyncMap(
        (doc) async {
          final data = doc.data();
          if (data == null) return <UserModel>[];
          final blocked = List<String>.from(data['blocked'] ?? []);
          if (blocked.isEmpty) return <UserModel>[];
          final futures = blocked.map((id) => getUserById(id));
          final list = await Future.wait(futures);
          return list.whereType<UserModel>().toList();
        },
      );
    });
  }

  /// Helper that returns the list of blocked user IDs (not full models).
  Future<List<String>> getBlockedIds() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final doc = await _usersCollection.doc(uid).get();
    final data = doc.data();
    if (data == null) return [];
    return List<String>.from(data['blocked'] ?? []);
  }

  /// Stream of blocked user IDs. Useful for filtering feeds in real time.
  Stream<List<String>> blockedIdsStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      final uid = user?.uid;
      if (uid == null) return Stream.value(<String>[]);
      return _usersCollection.doc(uid).snapshots().handleError((_) {}).map((
        snap,
      ) {
        final data = snap.data();
        if (data == null) return <String>[];
        return List<String>.from(data['blocked'] ?? []);
      });
    });
  }

  // Search users by name (case-insensitive, client-side filtering)
  Future<List<UserModel>> searchUsers(String query) async {
    final queryLower = query.toLowerCase();
    final blocked = await getBlockedIds();

    // Firestore range queries are case-sensitive, so we fetch users and filter client-side
    // First try exact match with original case
    var snapshot = await _usersCollection
        .orderBy('displayName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(50)
        .get();

    // If no results with original case, fetch all users with displayName starting with same first letter
    if (snapshot.docs.isEmpty && query.isNotEmpty) {
      // Fetch more users and filter client-side for case-insensitive match
      snapshot = await _usersCollection.limit(200).get();
    }

    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where(
          (u) =>
              !blocked.contains(u.uid) &&
              u.displayName.toLowerCase().contains(queryLower),
        )
        .toList();
  }

  // Get followers
  Stream<List<UserModel>> getFollowers(String userId) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<UserModel>[]);
      return _usersCollection
          .where('following', arrayContains: userId)
          .snapshots()
          .handleError((_) {})
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  // Get following
  Stream<List<UserModel>> getFollowing(String userId) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<UserModel>[]);
      return _usersCollection
          .where('followers', arrayContains: userId)
          .snapshots()
          .handleError((_) {})
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          );
    });
  }

  // Stream user changes
  Stream<UserModel?> streamUser(String uid) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return _usersCollection
          .doc(uid)
          .snapshots()
          .handleError((_) {})
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
    });
  }

  // Stream current user
  Stream<UserModel?> streamCurrentUser() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);
    return streamUser(uid);
  }

  // Delete user account
  Future<void> deleteUser() async {
    final uid = currentUserId;
    if (uid == null) return;

    // Delete profile photo
    try {
      await _storage.ref().child('profile_photos/$uid.jpg').delete();
    } catch (e) {
      // Photo may not exist
    }

    // Delete user document
    await _usersCollection.doc(uid).delete();

    // Delete Firebase Auth account
    await _auth.currentUser?.delete();
  }

  // ── Nickname (gợi nhớ tên) ──────────────────────────────────────────

  /// Set a private nickname for [otherUserId].
  /// Pass `null` or empty string to clear the nickname.
  Future<void> setNickname(String otherUserId, String? nickname) async {
    final uid = currentUserId;
    if (uid == null) return;
    final ref = _usersCollection
        .doc(uid)
        .collection('nicknames')
        .doc(otherUserId);
    if (nickname == null || nickname.trim().isEmpty) {
      await ref.delete();
    } else {
      await ref.set({
        'nickname': nickname.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get the nickname the current user set for [otherUserId].
  Future<String?> getNickname(String otherUserId) async {
    final uid = currentUserId;
    if (uid == null) return null;
    final doc = await _usersCollection
        .doc(uid)
        .collection('nicknames')
        .doc(otherUserId)
        .get();
    if (doc.exists) {
      return doc.data()?['nickname'] as String?;
    }
    return null;
  }

  /// Real-time stream of the nickname for [otherUserId].
  Stream<String?> nicknameStream(String otherUserId) {
    return _auth.authStateChanges().asyncExpand((user) {
      final uid = user?.uid;
      if (uid == null) return Stream.value(null);
      return _usersCollection
          .doc(uid)
          .collection('nicknames')
          .doc(otherUserId)
          .snapshots()
          .handleError((_) {})
          .map((snap) {
            if (snap.exists) return snap.data()?['nickname'] as String?;
            return null;
          });
    });
  }
}
