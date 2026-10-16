import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';

class Taikhoanriengtu extends StatefulWidget {
  const Taikhoanriengtu({super.key});

  @override
  State<Taikhoanriengtu> createState() => _TaikhoanriengtuState();
}

class _TaikhoanriengtuState extends State<Taikhoanriengtu> {
  final FirebaseAccountService _accountService = FirebaseAccountService();
  bool _isPrivate = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _accountService.getAccountSettings();
      if (!mounted) return;
      setState(() {
        _isPrivate = settings.isPrivate;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải cài đặt: ${e.toString()}')),
      );
    }
  }

  Future<void> _togglePrivate(bool value) async {
    setState(() => _isPrivate = value);
    try {
      await _accountService.updatePrivateAccount(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPrivate = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản riêng tư'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Khi bật chế độ riêng tư, chỉ người theo dõi đã được chấp nhận mới xem được bài viết, album và video của bạn.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  value: _isPrivate,
                  onChanged: _togglePrivate,
                  title: const Text('Tài khoản riêng tư'),
                  subtitle: Text(
                    _isPrivate
                        ? 'Chỉ người theo dõi đã duyệt mới xem được nội dung.'
                        : 'Mọi người đều có thể xem nội dung của bạn.',
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Khi bật tài khoản riêng tư',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const _InfoRow(
                  icon: Icons.visibility_off_outlined,
                  title: 'Người lạ không xem được bài viết',
                ),
                const _InfoRow(
                  icon: Icons.person_add_alt_outlined,
                  title: 'Người theo dõi mới cần được chấp nhận',
                ),
                const _InfoRow(
                  icon: Icons.lock_outline,
                  title: 'Album và video sẽ được bảo vệ',
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}
