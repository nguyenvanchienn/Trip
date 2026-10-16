import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service lưu danh sách email (Firebase)
class EmailListService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  /// Kiểm tra email đã tồn tại trong hệ thống chưa (cả primary và additional)
  static Future<bool> isEmailExistsInSystem(String email) async {
    final lowerEmail = email.toLowerCase();
    try {
      // Check in Firebase Auth (primary emails)
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(lowerEmail);
        if (methods.isNotEmpty) return true;
      } catch (_) {}

      // Check in Firestore additionalEmails (stored in lowercase)
      final query = await _firestore
          .collection('users')
          .where('additionalEmails', arrayContains: lowerEmail)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Tìm user bằng additional email và trả về auth email của họ
  static Future<Map<String, String>?> findUserByAdditionalEmail(
    String email,
  ) async {
    final lowerEmail = email.toLowerCase();
    try {
      final query = await _firestore
          .collection('users')
          .where('additionalEmails', arrayContains: lowerEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        return {'uid': doc.id, 'authEmail': data['email'] as String? ?? ''};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getEmailsWithPrimary() async {
    final uid = _uid;
    if (uid == null) return {'emails': <String>[], 'primary': null};

    try {
      // Get primary email from Auth
      final authEmail = _auth.currentUser?.email;

      // Get additional emails and primary preference from Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final List<String> emails = [];
      if (authEmail != null && authEmail.isNotEmpty) {
        emails.add(authEmail);
      }

      if (data != null) {
        final additionalEmails = data['additionalEmails'] as List<dynamic>?;
        if (additionalEmails != null) {
          emails.addAll(additionalEmails.cast<String>());
        }
      }

      // Get stored primary preference, default to auth email
      final storedPrimary = data?['primaryEmailPreference'] as String?;
      final primary = (storedPrimary != null && emails.contains(storedPrimary))
          ? storedPrimary
          : authEmail;

      return {'emails': emails, 'primary': primary};
    } catch (e) {
      return {'emails': <String>[], 'primary': null};
    }
  }

  static Future<List<String>> getEmails() async {
    final result = await getEmailsWithPrimary();
    return result['emails'] as List<String>;
  }

  static Future<void> setEmails(List<String> list) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      // Primary email is managed by Firebase Auth, we only store additional emails
      final authEmail = _auth.currentUser?.email?.toLowerCase();
      // Store emails in lowercase for consistent querying
      final additionalEmails = list
          .map((e) => e.toLowerCase())
          .where((e) => e != authEmail)
          .toList();

      await _firestore.collection('users').doc(uid).update({
        'additionalEmails': additionalEmails,
      });
    } catch (e) {
      // Handle error
    }
  }

  static Future<void> setPrimaryEmailPreference(String email) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'primaryEmailPreference': email,
      });
    } catch (e) {
      // Handle error
    }
  }

  /// Thay đổi email chính trong Firebase Auth
  /// Yêu cầu mật khẩu để re-authenticate
  static Future<String?> changePrimaryEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'Chưa đăng nhập';

    final oldEmail = user.email;
    if (oldEmail == null) return 'Không tìm thấy email hiện tại';

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: oldEmail,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email in Firebase Auth using verifyBeforeUpdateEmail
      // This will send a verification email to the new address
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update Firestore: add old email to additionalEmails, remove new email
      final uid = _uid;
      if (uid != null) {
        final doc = await _firestore.collection('users').doc(uid).get();
        final data = doc.data();
        final additionalEmails =
            (data?['additionalEmails'] as List<dynamic>?)?.cast<String>() ?? [];

        // Add old email to additional list if not there
        if (!additionalEmails.contains(oldEmail.toLowerCase())) {
          additionalEmails.add(oldEmail.toLowerCase());
        }

        // Remove new email from additional list
        additionalEmails.remove(newEmail.toLowerCase());

        await _firestore.collection('users').doc(uid).update({
          'email': newEmail.toLowerCase(),
          'additionalEmails': additionalEmails,
          'primaryEmailPreference': newEmail.toLowerCase(),
        });
      }

      return null; // Success - verification email sent
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Mật khẩu không đúng';
      } else if (e.code == 'requires-recent-login') {
        return 'Vui lòng đăng nhập lại để thực hiện';
      } else if (e.code == 'email-already-in-use') {
        return 'Email này đã được sử dụng bởi tài khoản khác';
      }
      return e.message ?? 'Đã có lỗi xảy ra';
    } catch (e) {
      return e.toString();
    }
  }

  /// Thêm email mới - trả về lỗi nếu email đã tồn tại
  static Future<String?> addEmailWithCheck(String email) async {
    final lowerEmail = email.toLowerCase();

    // Check if already in current user's list
    final list = await getEmails();
    final lowerList = list.map((e) => e.toLowerCase()).toList();
    if (lowerList.contains(lowerEmail)) {
      return 'Email này đã có trong danh sách';
    }

    // Check if email exists in system (another user)
    final exists = await isEmailExistsInSystem(lowerEmail);
    if (exists) {
      return 'Email này đã được sử dụng bởi tài khoản khác';
    }

    // Add to list (lowercase)
    list.add(lowerEmail);
    await setEmails(list);
    return null; // Success
  }

  static Future<void> addEmail(String email) async {
    final lowerEmail = email.toLowerCase();
    final list = await getEmails();
    final lowerList = list.map((e) => e.toLowerCase()).toList();
    if (!lowerList.contains(lowerEmail)) {
      list.add(lowerEmail);
      await setEmails(list);
    }
  }

  static Future<void> updateEmail(
    int index,
    String email,
    String? primaryEmail,
  ) async {
    final list = await getEmails();

    // Don't allow editing primary email
    if (index >= 0 && index < list.length && list[index] == primaryEmail) {
      return;
    }

    if (index >= 0 && index < list.length) {
      list[index] = email;
      await setEmails(list);
    }
  }

  static Future<bool> removeEmail(String email, String? primaryEmail) async {
    final lowerEmail = email.toLowerCase();
    final lowerPrimary = primaryEmail?.toLowerCase();
    final authEmail = _auth.currentUser?.email?.toLowerCase();

    // Cannot remove primary email
    if (lowerEmail == lowerPrimary) {
      return false;
    }

    // Cannot remove Firebase Auth email (original login email)
    if (lowerEmail == authEmail) {
      return false;
    }

    final list = await getEmails();
    // Find the email in list (case-insensitive)
    final indexToRemove = list.indexWhere((e) => e.toLowerCase() == lowerEmail);
    if (indexToRemove >= 0) {
      list.removeAt(indexToRemove);
      await setEmails(list);
      return true;
    }
    return false;
  }

  static Future<void> removeAt(int index, String? primaryEmail) async {
    final list = await getEmails();
    final lowerPrimary = primaryEmail?.toLowerCase();

    // Don't allow removing primary email
    if (index >= 0 &&
        index < list.length &&
        list[index].toLowerCase() == lowerPrimary) {
      return;
    }

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
  String? _primaryEmail;
  String? _authEmail; // Email đăng ký ban đầu (Firebase Auth)

  @override
  void initState() {
    super.initState();
    _authEmail = FirebaseAuth.instance.currentUser?.email;
    _load();
  }

  Future<void> _load() async {
    final result = await EmailListService.getEmailsWithPrimary();
    _emails = result['emails'] as List<String>;
    _primaryEmail = result['primary'] as String?;
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
          keyboardType: TextInputType.emailAddress,
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
    final email = ctl.text.trim().toLowerCase();
    final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!regex.hasMatch(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
      return;
    }

    // Show loading
    setState(() => _loading = true);

    final error = await EmailListService.addEmailWithCheck(email);
    await _load();

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm email')));
      }
    }
  }

  Future<void> _editEmail(int index) async {
    // Don't allow editing primary email (case-insensitive)
    if (_emails[index].toLowerCase() == _primaryEmail?.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email chính không thể chỉnh sửa tại đây'),
        ),
      );
      return;
    }

    final ctl = TextEditingController(text: _emails[index]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Chỉnh sửa email'),
        content: TextField(
          controller: ctl,
          keyboardType: TextInputType.emailAddress,
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
    await EmailListService.updateEmail(index, email, _primaryEmail);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật')));
    }
  }

  Future<void> _removeEmail(int index) async {
    final emailToRemove = _emails[index];

    // Don't allow removing primary email (case-insensitive)
    if (emailToRemove.toLowerCase() == _primaryEmail?.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xoá email chính')),
      );
      return;
    }

    // Don't allow removing Firebase Auth email (original login email)
    if (emailToRemove.toLowerCase() == _authEmail?.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xoá email đăng ký ban đầu')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xoá "$emailToRemove" không?'),
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

    setState(() => _loading = true);
    final removed = await EmailListService.removeEmail(
      emailToRemove,
      _primaryEmail,
    );
    await _load();

    if (mounted) {
      if (removed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xoá')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xoá email này'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setPrimaryEmail(int index) async {
    final newEmail = _emails[index];
    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;

    // Request password and confirmation
    final password = await showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Xác nhận đổi email chính'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đổi email chính sang:\n$newEmail',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Một email xác minh sẽ được gửi đến địa chỉ mới. '
                'Sau khi xác minh, email mới sẽ trở thành email đăng nhập chính.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nhập mật khẩu hiện tại',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(null),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(c).pop(passwordCtrl.text),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );

    if (password == null || password.isEmpty) return;

    setState(() => _loading = true);

    try {
      final error = await EmailListService.changePrimaryEmail(
        newEmail: newEmail,
        password: password,
      );

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      } else {
        // Reload to update UI
        _authEmail = newEmail; // Update local auth email
        await _load();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email xác minh đã được gửi đến $newEmail. '
                'Vui lòng kiểm tra hộp thư để hoàn tất.',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEmailOptions(int index) {
    final email = _emails[index];
    final isPrimary = email.toLowerCase() == _primaryEmail?.toLowerCase();
    final isAuthEmail = email.toLowerCase() == _authEmail?.toLowerCase();

    if (isPrimary) {
      // Primary email - just show info
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email chính không thể chỉnh sửa tại đây'),
        ),
      );
      return;
    }

    // If this is the auth email (original), only allow setting as primary
    if (isAuthEmail) {
      showModalBottomSheet(
        context: context,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Đây là email đăng ký ban đầu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Đặt làm email chính'),
                onTap: () {
                  Navigator.pop(c);
                  _setPrimaryEmail(index);
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Đặt làm email chính'),
              onTap: () {
                Navigator.pop(c);
                _setPrimaryEmail(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(c);
                _editEmail(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xoá', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(c);
                _removeEmail(index);
              },
            ),
          ],
        ),
      ),
    );
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
                          : _emails.asMap().entries.map((e) {
                              final isPrimary =
                                  e.value.toLowerCase() ==
                                  _primaryEmail?.toLowerCase();
                              final isAuthEmail =
                                  e.value.toLowerCase() ==
                                  _authEmail?.toLowerCase();
                              return Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.email_outlined),
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
                                              color: Colors.blue.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Chính',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        if (isAuthEmail && !isPrimary)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Gốc',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: (isPrimary || isAuthEmail)
                                        ? const Icon(
                                            Icons.lock_outline,
                                            size: 20,
                                          )
                                        : const Icon(Icons.chevron_right),
                                    onTap: () => _showEmailOptions(e.key),
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
