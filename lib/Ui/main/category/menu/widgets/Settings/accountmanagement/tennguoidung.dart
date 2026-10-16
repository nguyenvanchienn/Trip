import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_user_service.dart';

class TenNguoiDungService {
  static final FirebaseUserService _userService = FirebaseUserService();

  static Future<String?> getName() async {
    return _userService.getUsername();
  }

  static Future<({bool success, int? daysRemaining})> setName(
    String? name,
  ) async {
    if (name == null || name.isEmpty) {
      return (success: false, daysRemaining: null);
    }
    return _userService.updateUsername(name);
  }

  static Future<bool> isAvailable(String name) async {
    return _userService.isUsernameAvailable(name);
  }

  static Future<int?> getDaysRemaining() async {
    return _userService.getDaysUntilUsernameChange();
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
  bool _available = true;
  bool _checking = false;
  bool _hasChanges = false;
  String? _originalUsername;
  int? _daysRemaining;

  final _usernameRegexp = RegExp(r'^[a-z0-9._]+$');

  @override
  void initState() {
    super.initState();
    _loadData();
    _controller.addListener(() {
      final text = _controller.text.trim().toLowerCase();
      _hasChanges = text.isNotEmpty && text != _originalUsername;
      _validate(_controller.text);
      _checkAvailability(_controller.text);
    });
  }

  Future<void> _loadData() async {
    final username = await TenNguoiDungService.getName();
    final days = await TenNguoiDungService.getDaysRemaining();
    if (mounted) {
      // Don't set text, keep field empty - show original as hint
      _originalUsername = username;
      setState(() {
        _daysRemaining = days;
        _loading = false;
      });
    }
  }

  void _validate(String text) {
    final t = text.trim().toLowerCase();
    final ok = t.isNotEmpty && _usernameRegexp.hasMatch(t);
    if (ok != _valid) setState(() => _valid = ok);
  }

  Future<void> _checkAvailability(String text) async {
    final t = text.trim().toLowerCase();

    // If empty or same as current, no need to check
    if (t.isEmpty || t == _originalUsername) {
      setState(() {
        _available = true;
        _checking = false;
      });
      return;
    }

    if (!_usernameRegexp.hasMatch(t)) {
      setState(() => _checking = false);
      return;
    }

    setState(() => _checking = true);

    // Debounce - wait a bit before checking
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if text changed during delay
    if (_controller.text.trim().toLowerCase() != t) return;

    final isAvailable = await TenNguoiDungService.isAvailable(t);
    if (mounted && _controller.text.trim().toLowerCase() == t) {
      setState(() {
        _available = isAvailable;
        _checking = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim().toLowerCase();

    // If empty, don't change anything, just go back
    if (name.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    // If same as original, don't change, just go back
    if (name == _originalUsername) {
      Navigator.of(context).pop();
      return;
    }

    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên người dùng không hợp lệ')),
      );
      return;
    }

    final result = await TenNguoiDungService.setName(name);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên người dùng đã được lưu')),
      );
      Navigator.of(context).pop();
    } else if (result.daysRemaining != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn cần đợi ${result.daysRemaining} ngày nữa để đổi tên người dùng',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên người dùng đã được sử dụng bởi người khác'),
        ),
      );
    }
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
              // Enable when: not checking AND (no changes OR (has changes AND valid AND available))
              // AND allowed to change (days remaining)
              onPressed:
                  !_checking &&
                      (!_hasChanges || (_hasChanges && _valid && _available)) &&
                      (_daysRemaining == null ||
                          _daysRemaining == 0 ||
                          !_hasChanges)
                  ? _save
                  : null,
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
                                hintText: _originalUsername ?? 'Tên người dùng',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).hintColor.withOpacity(0.5),
                                    ),
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
                          // Status indicator - only show when user typed something different
                          if (_hasChanges && _checking)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else if (_hasChanges && _valid && _available)
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
                            )
                          else if (_hasChanges && _valid && !_available)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_hasChanges && !_available && _valid && !_checking)
                      Text(
                        'Tên người dùng này đã được sử dụng',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.red),
                      )
                    else
                      Text(
                        'Bạn có thể sử dụng tên người dùng hiện tại của mình trên Trip là ${_controller.text.isEmpty ? (_originalUsername ?? '') : _controller.text}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    if (_daysRemaining != null && _daysRemaining! > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Bạn có thể thay đổi tên người dùng sau $_daysRemaining ngày nữa.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lưu ý: Bạn chỉ có thể thay đổi tên người dùng mỗi 7 ngày một lần.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
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
