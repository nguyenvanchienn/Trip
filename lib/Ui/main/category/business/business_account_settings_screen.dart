import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';

import 'business_settings_sections.dart';

class BusinessAccountSettingsScreen extends StatefulWidget {
  const BusinessAccountSettingsScreen({super.key});

  @override
  State<BusinessAccountSettingsScreen> createState() =>
      _BusinessAccountSettingsScreenState();
}

class _BusinessAccountSettingsScreenState
    extends State<BusinessAccountSettingsScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = FirebaseAccountService().getExtendedProfile();
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = FirebaseAccountService().getExtendedProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt doanh nghiệp')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final ownerProfile =
              (data['ownerProfile'] as Map<String, dynamic>?) ?? {};
          final businessProfile =
              (data['businessProfile'] as Map<String, dynamic>?) ?? {};
          if (businessProfile.isEmpty) {
            return const Center(child: Text('Chưa có tài khoản doanh nghiệp'));
          }

          final media =
              (businessProfile['media'] as Map<String, dynamic>?) ?? {};
          final avatarPath = media['avatarPath'] as String?;
          final shopImagePaths = List<String>.from(
            media['shopImagePaths'] ?? [],
          );
          final licensePath = media['licensePath'] as String?;
          final locationImagePaths = List<String>.from(
            media['locationImagePaths'] ?? [],
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingTile(
                context,
                title: 'Thông tin cá nhân',
                subtitle: _buildOwnerSummary(ownerProfile),
                onTap: () => _openPersonalInfo(context, ownerProfile),
              ),
              _buildSettingTile(
                context,
                title: 'Thông tin cửa hàng',
                subtitle: _buildBusinessSummary(businessProfile),
                onTap: () => _openBusinessInfo(context, businessProfile),
              ),
              _buildSettingTile(
                context,
                title: 'Giờ mở cửa',
                subtitle: _formatOpenHoursSummary(businessProfile['openHours']),
                onTap: () => _openOpenHours(context, businessProfile),
              ),
              _buildSettingTile(
                context,
                title: 'Tin nhắn tự động',
                subtitle: _formatAutoReplySummary(businessProfile['autoReply']),
                onTap: () => _openAutoReply(context, businessProfile),
              ),
              _buildSettingTile(
                context,
                title: 'Ảnh/Media',
                subtitle: _buildMediaSummary(
                  avatarPath,
                  shopImagePaths,
                  licensePath,
                  locationImagePaths,
                ),
                onTap: () =>
                    _openMedia(context, businessProfile: businessProfile),
              ),
              _buildSettingTile(
                context,
                title: 'Thanh toán',
                subtitle: 'Tài khoản nhận tiền, ví, ngân hàng',
                onTap: () => _openPayment(context, businessProfile),
              ),
              _buildSettingTile(
                context,
                title: 'Thông báo',
                subtitle: 'Đơn hàng, khuyến mãi',
                onTap: () => _openNotifications(context, businessProfile),
              ),
              _buildSettingTile(
                context,
                title: 'Hỗ trợ',
                subtitle: 'Liên hệ đội ngũ hỗ trợ',
                onTap: () => _openSupport(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ?? () => _showComingSoon(context, title),
    );
  }

  String _buildOwnerSummary(Map<String, dynamic> ownerProfile) {
    final name = (ownerProfile['name'] ?? '').toString();
    final phone = (ownerProfile['phone'] ?? '').toString();
    final email = (ownerProfile['email'] ?? '').toString();
    final parts = [
      name,
      phone,
      email,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Chưa cập nhật' : parts.join(' • ');
  }

  String _buildBusinessSummary(Map<String, dynamic> businessProfile) {
    final name = (businessProfile['name'] ?? '').toString();
    final address = (businessProfile['address'] ?? '').toString();
    final parts = [
      name,
      address,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Chưa cập nhật' : parts.join(' • ');
  }

  String _buildMediaSummary(
    String? avatarPath,
    List<String> shopImagePaths,
    String? licensePath,
    List<String> locationImagePaths,
  ) {
    final count = shopImagePaths.length + locationImagePaths.length;
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;
    final hasLicense = licensePath != null && licensePath.isNotEmpty;
    final parts = <String>[];
    parts.add(hasAvatar ? 'Có avatar' : 'Thiếu avatar');
    parts.add(hasLicense ? 'Có giấy phép' : 'Thiếu giấy phép');
    parts.add('Ảnh: $count');
    return parts.join(' • ');
  }

  String _formatOpenHoursSummary(dynamic openHours) {
    if (openHours is Map<String, dynamic>) {
      final days = List<int>.from(openHours['days'] ?? []);
      final open = (openHours['open'] ?? '').toString();
      final close = (openHours['close'] ?? '').toString();
      if (days.isEmpty || open.isEmpty || close.isEmpty) {
        return 'Chưa thiết lập';
      }
      return '${_formatDays(days)} • $open-$close';
    }
    if (openHours is String && openHours.trim().isNotEmpty) {
      return openHours;
    }
    return 'Chưa thiết lập';
  }

  String _formatAutoReplySummary(dynamic autoReply) {
    if (autoReply is Map<String, dynamic>) {
      if (autoReply['enabled'] == true) return 'Đang bật';
    }
    return 'Đang tắt';
  }

  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'Chưa chọn ngày';
    final sorted = [...days]..sort();
    final labels = sorted.map((day) => _weekdayLabel(day)).toList();
    return labels.join(', ');
  }

  String _weekdayLabel(int day) {
    switch (day) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return 'T?';
    }
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title đang phát triển')));
  }

  Future<void> _openPersonalInfo(
    BuildContext context,
    Map<String, dynamic> ownerProfile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessPersonalInfoPage(ownerProfile: ownerProfile),
      ),
    );
    _reloadProfile();
  }

  Future<void> _openBusinessInfo(
    BuildContext context,
    Map<String, dynamic> businessProfile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessInfoPage(businessProfile: businessProfile),
      ),
    );
    _reloadProfile();
  }

  Future<void> _openOpenHours(
    BuildContext context,
    Map<String, dynamic> businessProfile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OpenHoursPage(businessProfile: businessProfile),
      ),
    );
    _reloadProfile();
  }

  Future<void> _openAutoReply(
    BuildContext context,
    Map<String, dynamic> businessProfile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AutoReplySettingsPage(businessProfile: businessProfile),
      ),
    );
    _reloadProfile();
  }

  Future<void> _openMedia(
    BuildContext context, {
    required Map<String, dynamic> businessProfile,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessMediaPage(businessProfile: businessProfile),
      ),
    );
    _reloadProfile();
  }

  Future<void> _openPayment(
    BuildContext context,
    Map<String, dynamic> businessProfile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentSettingsPage(businessProfile: businessProfile),
      ),
    );
    _reloadProfile();
  }

  Future<void> _openNotifications(
    BuildContext context,
    Map<String, dynamic> businessProfile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NotificationSettingsPage(businessProfile: businessProfile),
      ),
    );
    _reloadProfile();
  }

  Future<void> _openSupport(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SupportPage()));
  }
}
