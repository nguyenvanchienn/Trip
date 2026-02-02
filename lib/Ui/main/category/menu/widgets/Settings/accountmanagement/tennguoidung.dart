import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TenNguoiDungService {
  static const _usernameKey = 'account_username';

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<void> setName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null || name.isEmpty) {
      await prefs.remove(_usernameKey);
    } else {
      await prefs.setString(_usernameKey, name);
    }
  }
}

class TenNguoiDungPage extends StatefulWidget {
  const TenNguoiDungPage({super.key});

  @override
  State<TenNguoiDungPage> createState() => _TenNguoiDungPageState();
}

class _TenNguoiDungPageState extends State<TenNguoiDungPage> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _valid = false;

  final _usernameRegexp = RegExp(r'^[a-z0-9._]+$');

  @override
  void initState() {
    super.initState();
    TenNguoiDungService.getName().then((v) {
      _controller.text = v ?? '';
      _validate(_controller.text);
      if (mounted) setState(() => _loading = false);
    });
    _controller.addListener(() {
      _validate(_controller.text);
    });
  }

  void _validate(String text) {
    final t = text.trim().toLowerCase();
    final ok = t.isNotEmpty && _usernameRegexp.hasMatch(t);
    if (ok != _valid) setState(() => _valid = ok);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên người dùng không được để trống')),
      );
      return;
    }
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên người dùng không hợp lệ')),
      );
      return;
    }

    await TenNguoiDungService.setName(name);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tên người dùng đã được lưu')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _valid ? _save : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('Xong'),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chỉnh sửa tên người dùng',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nếu bạn đổi tên người dùng, hệ thống cũng sẽ thay đổi URL trang cá nhân Trip của bạn tại trip.com/username.',
                    ),
                    const SizedBox(height: 18),

                    // username card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.35),
                        ),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.03),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Tên người dùng',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              cursorColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ),
                          if (_valid)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.green,
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn có thể sử dụng tên người dùng hiện tại của mình trên Trip là ${_controller.text.isEmpty ? '' : _controller.text}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(
                      height: 300,
                    ), // keep content scrollable above button
                  ],
                ),
              ),
            ),
    );
  }
}
