import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final String separator;
  ThousandsSeparatorInputFormatter({this.separator = '.'});

  String _format(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(separator);
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _format(digits);
    int offset = formatted.length - (digits.length - newValue.selection.end);
    if (offset < 0) offset = 0;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length < 0 ? 0 : offset,
      ),
    );
  }
}

class TaiChinhThongMinhPage extends StatefulWidget {
  const TaiChinhThongMinhPage({super.key});

  @override
  State<TaiChinhThongMinhPage> createState() => _TaiChinhThongMinhPageState();
}

class _TaiChinhThongMinhPageState extends State<TaiChinhThongMinhPage> {
  final FirebaseMenuService _menuService = FirebaseMenuService();
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filtered = [];
  String _filter = 'Tất cả'; // Lọc: Tất cả, Hôm nay, Tuần, Tháng
  StreamSubscription<List<ExpenseModel>>? _subscription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _load() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _subscription = _menuService.getExpensesStream().listen(
      (expenses) {
        _expenses = expenses;
        _applyFilter();
        if (mounted) setState(() => _loading = false);
      },
      onError: (error) {
        debugPrint('Error loading expenses: $error');
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Không thể tải dữ liệu. Vui lòng thử lại.';
          });
        }
      },
    );
  }

  void _applyFilter([String? filter]) {
    if (filter != null) _filter = filter;
    final now = DateTime.now();
    DateTime start;
    if (_filter == 'Hôm nay') {
      start = DateTime(now.year, now.month, now.day);
    } else if (_filter == 'Tuần') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else if (_filter == 'Tháng') {
      start = DateTime(now.year, now.month, 1);
    } else {
      start = DateTime.fromMillisecondsSinceEpoch(0);
    }

    _filtered = _expenses.where((e) {
      return e.date.isAfter(start) || _filter == 'Tất cả';
    }).toList();
    if (mounted) setState(() {});
  }

  double _totalAmount() {
    return _filtered.fold(0.0, (prev, e) => prev + e.amount);
  }

  Map<String, double> _categoryTotals() {
    final map = <String, double>{};
    for (final e in _filtered) {
      final cat = e.category.isEmpty ? 'Khác' : e.category;
      map[cat] = (map[cat] ?? 0) + e.amount;
    }
    return map;
  }

  String _fmt(num v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _addExpense() async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => const _ExpenseDialog(),
    );
    if (res != null) {
      await _menuService.addExpense(
        amount: (res['amount'] as num?)?.toDouble() ?? 0,
        category: res['category'] ?? 'Khác',
        note: res['title'] ?? '',
        date: DateTime.tryParse(res['date'] ?? '') ?? DateTime.now(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã thêm chi tiêu')));
    }
  }

  Future<void> _deleteExpense(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa chi tiêu'),
        content: const Text('Bạn có chắc muốn xóa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _menuService.deleteExpense(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _categoryTotals();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài chính thông minh'),
        actions: [
          DropdownButton<String>(
            value: _filter,
            underline: Container(),
            dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
            onChanged: (v) => _applyFilter(v),
            items: [
              'Tất cả',
              'Hôm nay',
              'Tuần',
              'Tháng',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng: ${_fmt(_totalAmount())} VNĐ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Biểu đồ donut + chú thích
                          Row(
                            children: [
                              // Biểu đồ donut
                              SizedBox(
                                width: 160,
                                height: 160,
                                child: DonutChart(data: totals),
                              ),
                              const SizedBox(width: 12),
                              // Chú thích và phân tích
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: totals.entries
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((kv) {
                                        final i = kv.key;
                                        final e = kv.value;
                                        final total = _totalAmount();
                                        final val = e.value;
                                        final pct = total > 0
                                            ? (val / total * 100)
                                            : 0.0;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color:
                                                      DonutChart.colorForIndex(
                                                        i,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(e.key)),
                                              Text(
                                                '${pct.toStringAsFixed(0)}%',
                                              ),
                                              const SizedBox(width: 12),
                                              Text('${_fmt(val)} VNĐ'),
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(child: Text('Không có chi tiêu'))
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final e = _filtered[i];
                              return Dismissible(
                                key: ValueKey(e.id),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 16),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                direction: DismissDirection.startToEnd,
                                onDismissed: (_) => _deleteExpense(e.id),
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                      e.note.isEmpty ? 'Chi tiêu' : e.note,
                                    ),
                                    subtitle: Text(
                                      '${e.category} • ${_formatDate(e.date)}',
                                    ),
                                    trailing: Text('${_fmt(e.amount)} VNĐ'),
                                    onTap: () {},
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog();

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _category = 'Ăn uống';
  DateTime _date = DateTime.now();

  Future<void> _pickDate() async {
    final res = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (res != null) setState(() => _date = res);
  }

  void _save() {
    final amt = double.tryParse(_amount.text.replaceAll('.', '').trim()) ?? 0.0;
    if (_title.text.trim().isEmpty || amt <= 0) return;
    final note = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': _title.text.trim(),
      'amount': amt,
      'category': _category,
      'date': _date.toIso8601String(),
    };
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm chi tiêu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(hintText: 'Tiêu đề'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: const InputDecoration(hintText: 'Số tiền'),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _category,
            items: [
              'Ăn uống',
              'Di chuyển',
              'Chỗ ở',
              'Giải trí',
              'Mua sắm',
              'Khác',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Ngày: ${_date.toLocal().toString().split(' ').first}'),
              const SizedBox(width: 8),
              TextButton(onPressed: _pickDate, child: const Text('Chọn')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        TextButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}

// Biểu đồ donut
class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  const DonutChart({super.key, required this.data});

  static const _defaultColors = <Color>[
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFFFC312),
    Color(0xFF0984E3),
    Color(0xFFFD79A8),
    Color(0xFF2D3436),
    Color(0xFFE17055),
    Color(0xFF00CEC9),
    Color(0xFFFDCB6E),
    Color(0xFFE84393),
    Color(0xFF74B9FF),
    Color(0xFF55EFC4),
    Color(0xFFA29BFE),
    Color(0xFFFF7675),
    Color(0xFFF8C291),
    Color(0xFFB2BEC3),
  ];

  static Color colorForIndex(int idx) =>
      _defaultColors[idx % _defaultColors.length];

  static String fmt(num v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.');
  }

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = entries.fold<double>(0, (a, b) => a + (b.value));
    final slices = entries
        .asMap()
        .entries
        .map(
          (kv) => _Slice(
            label: kv.value.key,
            value: kv.value.value,
            color: colorForIndex(kv.key),
          ),
        )
        .toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size.square(160),
          painter: DonutPainter(slices: slices),
        ),
        // Số tổng ở giữa (tự co khi quá dài)
        SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FittedBox sẽ thu nhỏ chữ nếu quá dài; Text có thể xuống dòng tối đa 2 hàng
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 80,
                  child: Text(
                    DonutChart.fmt(total),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tổng',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  _Slice({required this.label, required this.value, required this.color});
}

class DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.32;

    final total = slices.fold<double>(0, (a, b) => a + b.value);
    double start = -3.1415926535897932 / 2; // bắt đầu từ -pi/2
    for (final s in slices) {
      final sweep = total == 0
          ? 0.0
          : (s.value / total) * 2 * 3.1415926535897932;
      paint.color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }

    // Vòng trong để biểu đồ nhìn gọn hơn
    final inner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - paint.strokeWidth - 4, inner);
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}
