import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service cho danh sách số điện thoại (Firebase)
class PhoneListService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static Future<List<String>> getPhones() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return [];

      // Get main phone and additional phones
      final List<String> phones = [];
      if (data['phone'] != null && (data['phone'] as String).isNotEmpty) {
        phones.add(data['phone']);
      }

      final additionalPhones = data['additionalPhones'] as List<dynamic>?;
      if (additionalPhones != null) {
        phones.addAll(additionalPhones.cast<String>());
      }

      return phones;
    } catch (e) {
      return [];
    }
  }

  static Future<void> setPhones(List<String> list) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final mainPhone = list.isNotEmpty ? list.first : '';
      final additionalPhones = list.length > 1 ? list.sublist(1) : <String>[];

      await _firestore.collection('users').doc(uid).update({
        'phone': mainPhone,
        'additionalPhones': additionalPhones,
      });
    } catch (e) {
      // Handle error
    }
  }

  static Future<void> addPhone(String phone) async {
    final list = await getPhones();
    if (!list.contains(phone)) {
      list.add(phone);
      await setPhones(list);
    }
  }

  static Future<void> updatePhone(int index, String phone) async {
    final list = await getPhones();
    if (index >= 0 && index < list.length) {
      list[index] = phone;
      await setPhones(list);
    }
  }

  static Future<void> removeAt(int index) async {
    final list = await getPhones();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await setPhones(list);
    }
  }
}

class PhoneListPage extends StatefulWidget {
  const PhoneListPage({super.key});

  @override
  State<PhoneListPage> createState() => _PhoneListPageState();
}

class _PhoneListPageState extends State<PhoneListPage> {
  List<String> _phones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _phones = await PhoneListService.getPhones();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addPhone() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thêm số di động'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: 'nhập số di động'),
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
    final phone = ctl.text.trim();
    final regex = RegExp(r"^[+0-9\s()-]{6,20}$");
    if (!regex.hasMatch(phone)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }
    await PhoneListService.addPhone(phone);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã thêm số di động')));
    }
  }

  Future<void> _editPhone(int index) async {
    final ctl = TextEditingController(text: _phones[index]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Chỉnh sửa số di động'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: 'nhập số di động'),
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
    final phone = ctl.text.trim();
    final regex = RegExp(r"^[+0-9\s()-]{6,20}$");
    if (!regex.hasMatch(phone)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }
    await PhoneListService.updatePhone(index, phone);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật')));
    }
  }

  Future<void> _removePhone(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xoá số này không?'),
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
    await PhoneListService.removeAt(index);
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
                    'Quản lý số di động của bạn. Dùng thông tin này để truy cập trang cá nhân hoặc xác minh tài khoản.',
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
                      children: _phones.isEmpty
                          ? [
                              const ListTile(
                                title: Text('Chưa có số điện thoại nào'),
                              ),
                            ]
                          : _phones.asMap().entries.map((e) {
                              final isPrimary = e.key == 0;
                              return Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.phone_android_outlined,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(e.value)),
                                        if (isPrimary)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Chính',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _editPhone(e.key),
                                    onLongPress: isPrimary
                                        ? null
                                        : () => _removePhone(e.key),
                                  ),
                                  const Divider(height: 1),
                                ],
                              );
                            }).toList(),
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
                      onPressed: _addPhone,
                      child: const Text('Thêm số di động'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
