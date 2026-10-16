import 'dart:io';
import 'package:tourn/data/firebase/firebase_user_service.dart';
import 'package:tourn/models/user_model.dart';

abstract class UserRepository {
  String? get currentUserId;
  Future<void> createUser(dynamic firebaseUser, {String? displayName});
  Future<UserModel?> getUserById(String uid);
  Future<UserModel?> getCurrentUser();
  Future<void> updateUser(UserModel user);
  Future<void> updateDisplayName(String displayName);
  Future<void> updateBio(String bio);
  Future<String?> updateProfilePhoto(File imageFile);
  Future<bool> deleteProfilePhoto();
  Future<void> setOnlineStatus(bool isOnline);
  Future<void> followUser(String targetUserId);
  Future<void> unfollowUser(String targetUserId);
  Future<void> requestFollow(String targetUserId);
  Future<void> cancelFollowRequest(String targetUserId);
  Future<void> acceptFollowRequest(String requesterId);
  Future<void> declineFollowRequest(String requesterId);
  Future<bool> isFollowRequested(String targetUserId);
  Future<void> removeFollower(String followerUserId);
  Future<void> unfriendUser(String userId);
  Future<bool> isFollowing(String targetUserId);

  /// Trả về true nếu người dùng được chỉ định đang theo dõi người dùng hiện tại.
  Future<bool> isFollowingMe(String userId);
  Future<List<UserModel>> searchUsers(String query);
  Stream<List<UserModel>> getFollowers(String userId);
  Stream<List<UserModel>> getFollowing(String userId);
  Stream<UserModel?> streamUser(String uid);
  Stream<UserModel?> streamCurrentUser();
  Future<void> deleteUser();
}

class FirestoreUserRepository implements UserRepository {
  final FirebaseUserService _userService = FirebaseUserService();

  @override
  String? get currentUserId => _userService.currentUserId;

  @override
  Future<void> createUser(dynamic firebaseUser, {String? displayName}) async {
    return _userService.createUser(firebaseUser, displayName: displayName);
  }

  @override
  Future<UserModel?> getUserById(String uid) async {
    return _userService.getUserById(uid);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _userService.getCurrentUser();
  }

  @override
  Future<void> updateUser(UserModel user) async {
    return _userService.updateUser(user);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    return _userService.updateDisplayName(displayName);
  }

  @override
  Future<void> updateBio(String bio) async {
    return _userService.updateBio(bio);
  }

  @override
  Future<String?> updateProfilePhoto(File imageFile) async {
    return _userService.updateProfilePhoto(imageFile);
  }

  @override
  Future<bool> deleteProfilePhoto() async {
    return _userService.deleteProfilePhoto();
  }

  @override
  Future<void> setOnlineStatus(bool isOnline) async {
    return _userService.setOnlineStatus(isOnline);
  }

  @override
  Future<void> followUser(String targetUserId) async {
    return _userService.followUser(targetUserId);
  }

  @override
  Future<void> unfollowUser(String targetUserId) async {
    return _userService.unfollowUser(targetUserId);
  }

  @override
  Future<void> requestFollow(String targetUserId) async {
    return _userService.requestFollow(targetUserId);
  }

  @override
  Future<void> cancelFollowRequest(String targetUserId) async {
    return _userService.cancelFollowRequest(targetUserId);
  }

  @override
  Future<void> acceptFollowRequest(String requesterId) async {
    return _userService.acceptFollowRequest(requesterId);
  }

  @override
  Future<void> declineFollowRequest(String requesterId) async {
    return _userService.declineFollowRequest(requesterId);
  }

  @override
  Future<bool> isFollowRequested(String targetUserId) async {
    return _userService.isFollowRequested(targetUserId);
  }

  @override
  Future<void> removeFollower(String followerUserId) async {
    return _userService.removeFollower(followerUserId);
  }

  @override
  Future<void> unfriendUser(String userId) async {
    return _userService.unfriendUser(userId);
  }

  @override
  Future<bool> isFollowing(String targetUserId) async {
    return _userService.isFollowing(targetUserId);
  }

  @override
  Future<bool> isFollowingMe(String userId) async {
    return _userService.isFollowingMe(userId);
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    return _userService.searchUsers(query);
  }

  @override
  Stream<List<UserModel>> getFollowers(String userId) {
    return _userService.getFollowers(userId);
  }

  @override
  Stream<List<UserModel>> getFollowing(String userId) {
    return _userService.getFollowing(userId);
  }

  @override
  Stream<UserModel?> streamUser(String uid) {
    return _userService.streamUser(uid);
  }

  @override
  Stream<UserModel?> streamCurrentUser() {
    return _userService.streamCurrentUser();
  }

  @override
  Future<void> deleteUser() async {
    return _userService.deleteUser();
  }
}
