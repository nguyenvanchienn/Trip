import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị lịch sử hoạt động tài khoản
class LichsutaikhoanPage extends StatefulWidget {
  const LichsutaikhoanPage({super.key});

  @override
  State<LichsutaikhoanPage> createState() => _LichsutaikhoanPageState();
}

class _LichsutaikhoanPageState extends State<LichsutaikhoanPage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final history = await _activityService.getAccountHistory(limit: 100);

    if (mounted) {
      setState(() {
        _history = history;
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'name_change':
        return Icons.badge_outlined;
      case 'email_change':
      case 'email_change_request':
        return Icons.email_outlined;
      case 'phone_change':
        return Icons.phone_outlined;
      case 'password_change':
        return Icons.lock_outline;
      case 'privacy_change':
        return Icons.shield_outlined;
      case 'birthday_change':
        return Icons.cake_outlined;
      case 'block_user':
        return Icons.block;
      case 'two_factor_enabled':
      case 'two_factor_disabled':
        return Icons.security;
      default:
        return Icons.history;
    }
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'login':
        return 'Đăng nhập';
      case 'logout':
        return 'Đăng xuất';
      case 'name_change':
        return 'Thay đổi tên';
      case 'email_change':
        return 'Thay đổi email';
      case 'email_change_request':
        return 'Yêu cầu thay đổi email';
      case 'phone_change':
        return 'Thay đổi số điện thoại';
      case 'password_change':
        return 'Thay đổi mật khẩu';
      case 'privacy_change':
        return 'Thay đổi quyền riêng tư';
      case 'birthday_change':
        return 'Thay đổi ngày sinh';
      case 'block_user':
        return 'Chặn tài khoản';
      case 'two_factor_enabled':
        return 'Bật xác thực 2 yếu tố';
      case 'two_factor_disabled':
        return 'Tắt xác thực 2 yếu tố';
      default:
        return 'Hoạt động tài khoản';
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'password_change':
      case 'two_factor_enabled':
        return Colors.blue;
      case 'block_user':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActionDescription(Map<String, dynamic> item) {
    final action = item['action'] as String?;
    final details = item['details'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'login':
        final method = details['method'] ?? 'normal';
        return 'Đăng nhập bằng $method';
      case 'name_change':
        final oldName = details['oldName'] ?? 'Không có';
        final newName = details['newName'] ?? 'Không có';
        return 'Từ "$oldName" thành "$newName"';
      case 'email_change_request':
        final newEmail = details['newEmail'] ?? '';
        return 'Yêu cầu thay đổi email sang $newEmail';
      case 'phone_change':
        final newPhone = details['newPhone'] ?? '';
        return 'Số điện thoại mới: $newPhone';
      case 'privacy_change':
        final setting = details['setting'] ?? '';
        final value = details['value'];
        return '$setting: ${value == true ? "Bật" : "Tắt"}';
      case 'block_user':
        return 'Đã chặn một tài khoản';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử tài khoản'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Không có lịch sử',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Các hoạt động đăng nhập và thay đổi tài khoản\nsẽ hiển thị ở đây',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final action = item['action'] as String? ?? '';
                  final timestamp = item['timestamp'];
                  final description = _getActionDescription(item);

                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getActionColor(action).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        _getActionIcon(action),
                        color: _getActionColor(action),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      _getActionTitle(action),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: description.isNotEmpty,
                  );
                },
              ),
            ),
    );
  }
}
