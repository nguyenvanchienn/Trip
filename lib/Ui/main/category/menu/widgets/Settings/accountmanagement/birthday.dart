import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayService {
  static const _birthdayKey = 'account_birthday';

  /// birthday stored as ISO date string (yyyy-MM-dd)
  static Future<String?> getBirthday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_birthdayKey);
  }

  static Future<void> setBirthday(String? birthdayIso) async {
    final prefs = await SharedPreferences.getInstance();
    if (birthdayIso == null || birthdayIso.isEmpty) {
      await prefs.remove(_birthdayKey);
    } else {
      await prefs.setString(_birthdayKey, birthdayIso);
    }
  }
}

class BirthdayPage extends StatefulWidget {
  const BirthdayPage({super.key});

  @override
  State<BirthdayPage> createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<BirthdayPage> {
  DateTime? _birthday;
  bool _loading = true;

  static const List<String> _monthsVN = [
    'tháng 1',
    'tháng 2',
    'tháng 3',
    'tháng 4',
    'tháng 5',
    'tháng 6',
    'tháng 7',
    'tháng 8',
    'tháng 9',
    'tháng 10',
    'tháng 11',
    'tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final iso = await BirthdayService.getBirthday();
    if (iso != null && iso.isNotEmpty) {
      try {
        _birthday = DateTime.tryParse(iso);
      } catch (_) {
        _birthday = null;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatBirthday(DateTime d) {
    final day = d.day;
    final month = _monthsVN[d.month - 1];
    final year = d.year;
    return '$day $month, $year';
  }

  Future<void> _edit() async {
    final initial = _birthday ?? DateTime.now();
    final first = DateTime(1900);
    final last = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      locale: const Locale('vi'),
    );
    if (picked == null) return;
    _birthday = picked;
    await BirthdayService.setBirthday(picked.toIso8601String());
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ngày sinh đã được lưu')));
  }

  void _showVisibilityInfo() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ai có thể nhìn thấy sinh nhật của bạn'),
        content: const Text(
          'Bạn có thể chọn ai được thấy ngày sinh của bạn. Hiện tại tùy chọn này là demo mẫu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const Text('Ngày sinh')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Khi bạn cho biết ngày sinh của mình, chúng tôi sẽ mang đến cho bạn trải nghiệm phù hợp với độ tuổi.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _birthday != null
                                ? _formatBirthday(_birthday!)
                                : 'Chưa thêm ngày sinh',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _edit,
                          child: const Text('Chỉnh sửa'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _showVisibilityInfo,
                  child: const Text('Ai có thể nhìn thấy sinh nhật của bạn'),
                ),
              ],
            ),
    );
  }
}
