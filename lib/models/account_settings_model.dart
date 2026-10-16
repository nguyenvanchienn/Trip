import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho cài đặt quyền riêng tư và bảo mật tài khoản
class AccountSettingsModel {
  /// Tài khoản riêng tư - chỉ người theo dõi được duyệt mới xem được nội dung
  final bool isPrivate;

  /// Hiển thị trạng thái hoạt động (online/offline)
  final bool showActivityStatus;

  /// Ai được phép bình luận: 'everyone', 'followers', 'no_one'
  final String allowComments;

  /// Ai được phép nhắc đến: 'everyone', 'followers', 'no_one'
  final String allowMentions;

  /// Ai được phép gửi tin nhắn: 'everyone', 'followers', 'no_one'
  final String allowMessages;

  /// Cho phép tải về nội dung
  final bool allowDownloads;

  /// Ai được phép gắn thẻ: 'everyone', 'followers', 'no_one'
  final String allowTags;

  /// Lọc bình luận xúc phạm
  final bool filterOffensiveComments;

  /// Lọc tin nhắn spam
  final bool filterSpamMessages;

  /// Cho phép nhận gợi ý nội dung
  final bool contentSuggestions;

  /// Bật thông báo đẩy
  final bool pushNotifications;

  /// Chế độ tối
  final bool darkMode;

  /// Xác thực 2 yếu tố
  final bool twoFactorEnabled;

  /// Tài khoản doanh nghiệp
  final bool isBusinessAccount;

  AccountSettingsModel({
    this.isPrivate = false,
    this.showActivityStatus = true,
    this.allowComments = 'everyone',
    this.allowMentions = 'everyone',
    this.allowMessages = 'followers',
    this.allowDownloads = true,
    this.allowTags = 'everyone',
    this.filterOffensiveComments = true,
    this.filterSpamMessages = true,
    this.contentSuggestions = true,
    this.pushNotifications = true,
    this.darkMode = false,
    this.twoFactorEnabled = false,
    this.isBusinessAccount = false,
  });

  /// Tạo instance với giá trị mặc định
  factory AccountSettingsModel.defaults() {
    return AccountSettingsModel();
  }

  factory AccountSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AccountSettingsModel(
      isPrivate: data['isPrivate'] ?? false,
      showActivityStatus: data['showActivityStatus'] ?? true,
      allowComments: data['allowComments'] ?? 'everyone',
      allowMentions: data['allowMentions'] ?? 'everyone',
      allowMessages: data['allowMessages'] ?? 'followers',
      allowDownloads: data['allowDownloads'] ?? true,
      allowTags: data['allowTags'] ?? 'everyone',
      filterOffensiveComments: data['filterOffensiveComments'] ?? true,
      filterSpamMessages: data['filterSpamMessages'] ?? true,
      contentSuggestions: data['contentSuggestions'] ?? true,
      pushNotifications: data['pushNotifications'] ?? true,
      darkMode: data['darkMode'] ?? false,
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      isBusinessAccount: data['isBusiness'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isPrivate': isPrivate,
      'showActivityStatus': showActivityStatus,
      'allowComments': allowComments,
      'allowMentions': allowMentions,
      'allowMessages': allowMessages,
      'allowDownloads': allowDownloads,
      'allowTags': allowTags,
      'filterOffensiveComments': filterOffensiveComments,
      'filterSpamMessages': filterSpamMessages,
      'contentSuggestions': contentSuggestions,
      'pushNotifications': pushNotifications,
      'darkMode': darkMode,
      'twoFactorEnabled': twoFactorEnabled,
      'isBusiness': isBusinessAccount,
    };
  }

  AccountSettingsModel copyWith({
    bool? isPrivate,
    bool? showActivityStatus,
    String? allowComments,
    String? allowMentions,
    String? allowMessages,
    bool? allowDownloads,
    String? allowTags,
    bool? filterOffensiveComments,
    bool? filterSpamMessages,
    bool? contentSuggestions,
    bool? pushNotifications,
    bool? darkMode,
    bool? twoFactorEnabled,
    bool? isBusinessAccount,
  }) {
    return AccountSettingsModel(
      isPrivate: isPrivate ?? this.isPrivate,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      allowComments: allowComments ?? this.allowComments,
      allowMentions: allowMentions ?? this.allowMentions,
      allowMessages: allowMessages ?? this.allowMessages,
      allowDownloads: allowDownloads ?? this.allowDownloads,
      allowTags: allowTags ?? this.allowTags,
      filterOffensiveComments:
          filterOffensiveComments ?? this.filterOffensiveComments,
      filterSpamMessages: filterSpamMessages ?? this.filterSpamMessages,
      contentSuggestions: contentSuggestions ?? this.contentSuggestions,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      darkMode: darkMode ?? this.darkMode,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      isBusinessAccount: isBusinessAccount ?? this.isBusinessAccount,
    );
  }

  /// Chuyển đổi giá trị privacy thành text hiển thị
  static String privacyValueToText(String value) {
    switch (value) {
      case 'everyone':
        return 'Mọi người';
      case 'followers':
        return 'Người theo dõi';
      case 'no_one':
        return 'Không ai';
      default:
        return 'Mọi người';
    }
  }

  /// Chuyển đổi text hiển thị thành giá trị privacy
  static String textToPrivacyValue(String text) {
    switch (text) {
      case 'Mọi người':
        return 'everyone';
      case 'Người theo dõi':
        return 'followers';
      case 'Không ai':
        return 'no_one';
      default:
        return 'everyone';
    }
  }
}
