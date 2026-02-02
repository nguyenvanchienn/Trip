import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

class ChangePasswork extends StatefulWidget {
  const ChangePasswork({super.key});

  @override
  State<ChangePasswork> createState() => _ChangePassworkState();
}

class _ChangePassworkState extends State<ChangePasswork> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _logoutOtherDevices = true;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  String? _newError;
  String? _confirmError;

  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _newController.addListener(_validatePasswords);
    _confirmController.addListener(_validatePasswords);
    _loadLastUpdate();
  }

  Future<void> _loadLastUpdate() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('password_last_update');
    if (s != null) {
      try {
        _lastUpdated = DateTime.parse(s);
      } catch (_) {}
    }
    setState(() {});
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _validatePasswords() {
    final newp = _newController.text;
    final conf = _confirmController.text;

    _newError = null;
    _confirmError = null;

    if (newp.isNotEmpty && !_isPasswordValid(newp)) {
      _newError = 'Ít nhất 6 ký tự, chữ, số & ký tự đặc biệt';
    }

    if (conf.isNotEmpty && newp != conf) {
      _confirmError = 'Không khớp';
    }

    setState(() {});
  }

  bool _isPasswordValid(String p) {
    if (p.length < 6) return false;
    final hasLetter = p.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = p.contains(RegExp(r'\d'));
    final hasSpecial = p.contains(RegExp(r'[^A-Za-z0-9]'));
    return hasLetter && hasDigit && hasSpecial;
  }

  bool get _canSubmit {
    return _currentController.text.isNotEmpty &&
        _newController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _newError == null &&
        _confirmError == null;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      final repo = RepositoryProvider.of<AuthenticationRepository>(context);
      await repo.updatePassword(
        currentPassword: _currentController.text.trim(),
        newPassword: _newController.text,
      );

      // save last updated date
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'password_last_update',
        DateTime.now().toIso8601String(),
      );
      _lastUpdated = DateTime.now();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu đã được thay đổi')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đặt lại mật khẩu chưa cài đặt')),
    );
  }

  // _openLearnMore removed: dialog is shown inline where needed

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).dividerColor),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đổi mật khẩu',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mật khẩu của bạn phải có tối thiểu 6 ký tự, đồng thời bao gồm cả chữ số, chữ cái và ký tự đặc biệt (!\$@%).',
                    ),
                    const SizedBox(height: 16),

                    // current password
                    TextField(
                      controller: _currentController,
                      obscureText: !_showCurrent,
                      decoration: InputDecoration(
                        hintText: _lastUpdated == null
                            ? 'Mật khẩu hiện tại'
                            : 'Mật khẩu hiện tại (Ngày cập nhật: ${_formatDate(_lastUpdated!)})',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.03),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border.copyWith(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _showCurrent = !_showCurrent),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _newController,
                      obscureText: !_showNew,
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu mới',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.03),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border.copyWith(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNew ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _showNew = !_showNew),
                        ),
                        errorText: _newError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _confirmController,
                      obscureText: !_showConfirm,
                      decoration: InputDecoration(
                        hintText: 'Nhập lại mật khẩu mới',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.03),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border.copyWith(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                        errorText: _confirmError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: _forgotPassword,
                      child: Text(
                        'Bạn quên mật khẩu ư?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Checkbox(
                          value: _logoutOtherDevices,
                          onChanged: (v) =>
                              setState(() => _logoutOtherDevices = v ?? true),
                        ),
                        Expanded(
                          child: Text(
                            'Đăng xuất khỏi các thiết bị khác. Hãy chọn mục này nếu người khác từng dùng tài khoản của bạn.',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSubmit && !_loading ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đổi mật khẩu'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Removed unused helper widgets: _buildField and _buildInfoText
// They were top-level helpers not referenced in this file.
