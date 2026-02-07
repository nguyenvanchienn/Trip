import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service lưu danh sách email (cho phép nhiều email)
class EmailListService {
  static const _key = 'account_emails';

  static Future<List<String>> getEmails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  static Future<void> setEmails(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
  }

  static Future<void> addEmail(String email) async {
    final list = await getEmails();
    if (!list.contains(email)) {
      list.add(email);
      await setEmails(list);
    }
  }

  static Future<void> updateEmail(int index, String email) async {
    final list = await getEmails();
    if (index >= 0 && index < list.length) {
      list[index] = email;
      await setEmails(list);
    }
  }

  static Future<void> removeAt(int index) async {
    final list = await getEmails();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await setEmails(list);
    }
  }
}

class EmailListPage extends StatefulWidget {
  const EmailListPage({super.key});

  @override
  State<EmailListPage> createState() => _EmailListPageState();
}

class _EmailListPageState extends State<EmailListPage> {
  List<String> _emails = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _emails = await EmailListService.getEmails();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addEmail() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thêm email'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: 'nhập email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final email = ctl.text.trim();
    final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!regex.hasMatch(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
      return;
    }
    await EmailListService.addEmail(email);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã thêm email')));
    }
  }

  Future<void> _editEmail(int index) async {
    final ctl = TextEditingController(text: _emails[index]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Chỉnh sửa email'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: 'nhập email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final email = ctl.text.trim();
    final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!regex.hasMatch(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
      return;
    }
    await EmailListService.updateEmail(index, email);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật')));
    }
  }

  Future<void> _removeEmail(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xoá email này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await EmailListService.removeAt(index);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xoá')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin liên hệ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Quản lý email liên hệ của bạn. Dùng thông tin này để truy cập trang cá nhân hoặc xác minh tài khoản.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: _emails.isEmpty
                          ? [const ListTile(title: Text('Chưa có email nào'))]
                          : _emails
                                .asMap()
                                .entries
                                .map(
                                  (e) => Column(
                                    children: [
                                      ListTile(
                                        leading: const Icon(
                                          Icons.email_outlined,
                                        ),
                                        title: Text(e.value),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                        ),
                                        onTap: () => _editEmail(e.key),
                                      ),
                                      const Divider(height: 1),
                                    ],
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addEmail,
                      child: const Text('Thêm email'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
