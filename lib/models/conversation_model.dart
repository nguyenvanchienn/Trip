import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType { private, group }

class ConversationModel {
  final String id;
  final ConversationType type;
  final String? name;
  final String? photoUrl;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;
  final Map<String, bool> mutedUsers; // per-user mute flag
  final Map<String, Timestamp?> muteExpiry; // when mute ends (null = indefinite)
  final DateTime createdAt;
  final String? createdBy;
  final bool isArchived;
  // List of user IDs who have accepted this conversation
  // Used for message requests - if a non-friend sends a message,
  // the receiver must accept before it appears in main chat list
  final List<String> acceptedBy;
  // User IDs who have hidden this conversation from their recent list
  final List<String> deletedFor;
  final bool isBusinessChat;

  ConversationModel({
    required this.id,
    this.type = ConversationType.private,
    this.name,
    this.photoUrl,
    required this.participants,
    this.participantNames = const {},
    this.participantPhotos = const {},
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.unreadCount = const {},
    this.mutedUsers = const {},
    Map<String, Timestamp?>? muteExpiry,
    required this.createdAt,
    this.createdBy,
    this.isArchived = false,
    this.acceptedBy = const [],
    this.deletedFor = const [],
    this.isBusinessChat = false,
  }) : muteExpiry = muteExpiry ?? {};

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safe parsing helpers
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      return [];
    }

    Map<String, String> safeStringMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) return Map<String, String>.from(value);
      return {};
    }

    Map<String, String?> safeNullableStringMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) return Map<String, String?>.from(value);
      return {};
    }

    Map<String, int> safeIntMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, int>.from(
          value.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
          ),
        );
      }
      return {};
    }

    return ConversationModel(
      id: doc.id,
      type: ConversationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ConversationType.private,
      ),
      name: data['name'],
      photoUrl: data['photoUrl'],
      participants: safeStringList(data['participants']),
      participantNames: safeStringMap(data['participantNames']),
      participantPhotos: safeNullableStringMap(data['participantPhotos']),
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: safeIntMap(data['unreadCount']),
      mutedUsers:
          (data['mutedUsers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v as bool),
          ) ??
          {},
      muteExpiry:
          (data['muteExpiry'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k.toString(), v == null ? null : (v as Timestamp)),
          ) ??
          {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      isArchived: data['isArchived'] ?? false,
      acceptedBy: safeStringList(data['acceptedBy']),
      deletedFor: safeStringList(data['deletedFor']),
      isBusinessChat: (data['isBusinessChat'] as bool? ?? false) ||
          (safeStringList(data['participants']).length == 2 &&
              safeStringList(data['participants'])[0] ==
                  safeStringList(data['participants'])[1]),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'name': name,
      'photoUrl': photoUrl,
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'unreadCount': unreadCount,
      'mutedUsers': mutedUsers,
      'muteExpiry': muteExpiry,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isArchived': isArchived,
      'acceptedBy': acceptedBy,
      'deletedFor': deletedFor,
      'isBusinessChat': isBusinessChat,
    };
  }

  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    String? name,
    String? photoUrl,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCount,
    Map<String, bool>? mutedUsers,
    Map<String, Timestamp?>? muteExpiry,
    DateTime? createdAt,
    String? createdBy,
    bool? isArchived,
    List<String>? acceptedBy,
    List<String>? deletedFor,
    bool? isBusinessChat,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      muteExpiry: muteExpiry ?? this.muteExpiry,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isArchived: isArchived ?? this.isArchived,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      deletedFor: deletedFor ?? this.deletedFor,
      isBusinessChat: isBusinessChat ?? this.isBusinessChat,
    );
  }

  String getDisplayName(String currentUserId) {
    if (type == ConversationType.group) {
      return name ?? 'Nhóm chat';
    }
    // if we weren't given a valid currentUserId (eg. empty or null), just
    // return the first non-empty participant name we can find.  this avoids
    // showing "Me" when the caller accidentally passes an empty string.
    if (currentUserId.isEmpty) {
      for (var id in participants) {
        final n = participantNames[id];
        if (n != null && n.isNotEmpty && n.toLowerCase() != 'me') {
          return n;
        }
      }
      return participantNames[participants.first] ?? 'Unknown';
    }

    final otherParticipant = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    String otherName = participantNames[otherParticipant] ?? 'Unknown';
    // if the name for the "other" participant is literally "Me" we
    // probably stored the placeholder for the current user.  prefer
    // returning a real name, but make sure not to accidentally return the
    // current user's own display name when we scan the map.
    if (otherName.toLowerCase() == 'me') {
      for (var entry in participantNames.entries) {
        if (entry.key == currentUserId) continue;
        final val = entry.value;
        if (val.toLowerCase() != 'me' && val.isNotEmpty) {
          otherName = val;
          break;
        }
      }
    }
    return otherName;
  }

  String? getDisplayPhoto(String currentUserId) {
    if (type == ConversationType.group) {
      return photoUrl;
    }
    final otherParticipant = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    return participantPhotos[otherParticipant];
  }

  /// Check if user has accepted this conversation
  bool hasAccepted(String userId) {
    // Creator always accepts by default
    if (createdBy == userId) return true;
    // Check acceptedBy list
    return acceptedBy.contains(userId);
  }

  /// Get the other participant's ID in a private conversation
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
  }
}
