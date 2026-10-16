import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? username; // unique username (e.g. name123456)
  final DateTime? lastUsernameChange; // last time username was changed
  final String? photoUrl;
  final String? coverPhotoUrl;
  final String? bio;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> followers;
  final List<String> following;
  final List<String> followRequests; // incoming follow requests
  final List<String> followRequested; // outgoing follow requests
  final List<String> restricted; // users this person has restricted
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isBusinessAccount;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username,
    this.lastUsernameChange,
    this.photoUrl,
    this.coverPhotoUrl,
    this.bio,
    this.phone,
    this.address,
    required this.createdAt,
    this.lastLoginAt,
    this.followers = const [],
    this.following = const [],
    this.followRequests = const [],
    this.followRequested = const [],
    this.restricted = const [],
    this.isOnline = false,
    this.lastSeen,
    this.isBusinessAccount = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safe list parsing helper
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      return [];
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      username: data['username'],
      lastUsernameChange: (data['lastUsernameChange'] as Timestamp?)?.toDate(),
      photoUrl: data['photoUrl'],
      coverPhotoUrl: data['coverPhotoUrl'],
      bio: data['bio'],
      phone: data['phone'],
      address: data['address'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      followers: safeStringList(data['followers']),
      following: safeStringList(data['following']),
      followRequests: safeStringList(data['followRequests']),
      followRequested: safeStringList(data['followRequested']),
      restricted: safeStringList(data['restricted']),
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      isBusinessAccount:
          data['isBusiness'] ?? data['isBusinessAccount'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'lastUsernameChange': lastUsernameChange != null
          ? Timestamp.fromDate(lastUsernameChange!)
          : null,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'bio': bio,
      'phone': phone,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'followers': followers,
      'following': following,
      'followRequests': followRequests,
      'followRequested': followRequested,
      'restricted': restricted,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isBusiness': isBusinessAccount,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    DateTime? lastUsernameChange,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? coverPhotoUrl,
    String? bio,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? followers,
    List<String>? following,
    List<String>? followRequests,
    List<String>? followRequested,
    List<String>? restricted,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isBusinessAccount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      lastUsernameChange: lastUsernameChange ?? this.lastUsernameChange,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      followRequests: followRequests ?? this.followRequests,
      followRequested: followRequested ?? this.followRequested,
      restricted: restricted ?? this.restricted,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isBusinessAccount: isBusinessAccount ?? this.isBusinessAccount,
    );
  }
}
