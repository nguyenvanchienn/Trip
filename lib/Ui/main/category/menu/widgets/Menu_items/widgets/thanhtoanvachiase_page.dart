import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

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
    // keep only digits
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _format(digits);

    // calculate selection
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

class ThanhToanVaChiaSePage extends StatefulWidget {
  const ThanhToanVaChiaSePage({super.key});

  @override
  State<ThanhToanVaChiaSePage> createState() => _ThanhToanVaChiaSePageState();
}

class _ThanhToanVaChiaSePageState extends State<ThanhToanVaChiaSePage> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final List<Map<String, dynamic>> _participants = [
    {
      'id': 'p1',
      'name': 'Bạn',
      'share': 0.0,
      'contribution': 0.0,
      'paidFor': '',
    },
  ];
  bool _equalSplit = true;
  final Map<String, double> _result = {}; // assigned expected amount
  final Map<String, double> _settlement = {}; // expected - contribution

  final String _historyKey = 'split_history_v1';
  List<Map<String, dynamic>> _history = [];

  String _fmt(num v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.');
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    _history = raw
        .map((s) {
          try {
            final d = jsonDecode(s);
            if (d is Map<String, dynamic>) return d;
            if (d is Map) return Map<String, dynamic>.from(d);
            return <String, dynamic>{};
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();

    // Normalize older records: ensure participants have assigned, contribution, settlement and total is numeric
    bool updated = false;
    for (var h in _history) {
      // normalize total
      if (h['total'] is String) {
        final n = num.tryParse(h['total']);
        if (n != null) {
          h['total'] = n;
          updated = true;
        }
      }

      final parts = (h['participants'] as List).cast<Map<String, dynamic>>();
      for (var p in parts) {
        // if old key 'amount' exists, map to 'assigned'
        if (p.containsKey('amount') && !p.containsKey('assigned')) {
          p['assigned'] = p['amount'];
          updated = true;
        }
        // ensure contribution exists
        if (!p.containsKey('contribution')) {
          p['contribution'] = 0;
          updated = true;
        }
        // ensure settlement exists
        final assigned = (p['assigned'] ?? p['amount']) as num? ?? 0;
        final contrib = (p['contribution'] as num?) ?? 0;
        final settle = (p['settlement'] as num?) ?? (assigned - contrib);
        if (p['settlement'] != settle) {
          p['settlement'] = settle;
          updated = true;
        }
      }
    }

    if (updated) {
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setStringList(
        _historyKey,
        _history.map((e) => jsonEncode(e)).toList(),
      );
    }

    setState(() {});
  }

  Future<void> _saveHistory(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, record);
    await prefs.setStringList(
      _historyKey,
      _history.map((e) => jsonEncode(e)).toList(),
    );
    setState(() {});
  }

  void _addParticipant() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thêm người tham gia'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Tên'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(ctrl.text.trim()),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      _participants.add({
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'name': res,
        'share': 0.0,
        'contribution': 0.0,
        'paidFor': '',
      });
      setState(() {});
    }
  }

  void _removeParticipant(String id) {
    if (_participants.length <= 1) return;
    _participants.removeWhere((p) => p['id'] == id);
    setState(() {});
  }

  void _calculate() {
    final total =
        double.tryParse(_amountCtrl.text.replaceAll('.', '').trim()) ?? 0.0;
    if (total <= 0 || _participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tổng tiền và ít nhất 1 người')),
      );
      return;
    }

    _result.clear();
    _settlement.clear();

    if (_equalSplit) {
      final per = double.parse(
        (total / _participants.length).toStringAsFixed(0),
      );
      for (final p in _participants) {
        _result[p['id']] = per;
      }
      // adjust remainder
      final rem = total - per * _participants.length;
      if (rem != 0) {
        _result[_participants.first['id']] =
            (_result[_participants.first['id']] ?? 0) + rem;
      }
    } else {
      // use provided share percentages or amounts (share field)
      final totalShare = _participants.fold<double>(
        0.0,
        (s, p) => s + (p['share'] as double? ?? 0.0),
      );
      if (totalShare <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhập tỷ lệ/chia sẻ cho từng người')),
        );
        return;
      }
      for (final p in _participants) {
        final share = (p['share'] as double? ?? 0.0) / totalShare;
        _result[p['id']] = double.parse((share * total).toStringAsFixed(0));
      }
      // adjust rounding
      final sum = _result.values.fold<double>(0.0, (a, b) => a + b);
      final diff = total - sum;
      if (diff != 0) {
        _result[_participants.first['id']] =
            (_result[_participants.first['id']] ?? 0) + diff;
      }
    }

    // calculate settlement considering contribution each has paid
    for (final p in _participants) {
      final contrib = (p['contribution'] as num?)?.toDouble() ?? 0.0;
      final expected = _result[p['id']] ?? 0.0;
      _settlement[p['id']] = double.parse(
        (expected - contrib).toStringAsFixed(0),
      );
    }

    setState(() {});
  }

  Future<void> _saveSettlement() async {
    if (_result.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có kết quả để lưu')));
      return;
    }

    final record = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'total': double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0,
      'note': _noteCtrl.text,
      'date': DateTime.now().toIso8601String(),
      'participants': _participants
          .map(
            (p) => {
              'id': p['id'],
              'name': p['name'],
              'assigned': _result[p['id']],
              'contribution': p['contribution'],
              'settlement': _settlement[p['id']],
              'paidFor': p['paidFor'] ?? '',
            },
          )
          .toList(),
    };

    await _saveHistory(record);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu giao dịch')));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _showShareSheet(BuildContext ctx, String message) async {
    final contacts = [
      {'name': 'Bạn', 'initials': 'B'},
      {'name': 'Minh', 'initials': 'M'},
      {'name': 'Lan', 'initials': 'L'},
      {'name': 'An', 'initials': 'A'},
      {'name': 'Thanh', 'initials': 'T'},
    ];

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) {
        final maxH = MediaQuery.of(ctx).size.height * 0.78;
        return SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Chia sẻ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(c).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: contacts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final ct = contacts[i];
                          return Column(
                            children: [
                              CircleAvatar(
                                child: Text((ct['initials'] ?? '').toString()),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  (ct['name'] ?? '').toString(),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxH * 0.5),
                        child: SingleChildScrollView(
                          child: SelectableText(message),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(c).pop();
                              try {
                                await Share.share(
                                  message,
                                  subject: 'Lịch sử giao dịch',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã mở tùy chọn chia sẻ'),
                                    ),
                                  );
                                }
                              } catch (_) {
                                await Clipboard.setData(
                                  ClipboardData(text: message),
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Không hỗ trợ chia sẻ — đã copy vào clipboard',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Chia sẻ'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: message),
                            );
                            Navigator.of(c).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép vào clipboard'),
                                ),
                              );
                            }
                          },
                          child: const Text('Sao chép'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán và chia tiền')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addParticipant,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm người'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Tổng tiền (VNĐ)',
                  prefixIcon: Icon(Icons.payments),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _equalSplit = true);
                        _calculate();
                      },
                      child: const Text('Chia đều'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _equalSplit = false);
                        _calculate();
                      },
                      child: const Text('Chia theo tỉ lệ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Danh sách người',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._participants.map((p) {
                        return Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _removeParticipant(p['id']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (!_equalSplit)
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 16),
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập tỉ lệ (vd: 55)',
                                      prefixIcon: Icon(Icons.percent),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12.0,
                                        horizontal: 12.0,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      final val = double.tryParse(v) ?? 0.0;
                                      setState(() => p['share'] = val);
                                    },
                                  ),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Trả cho (ví dụ: xăng, khách sạn)',
                                    prefixIcon: Icon(Icons.description),
                                  ),
                                  minLines: 1,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 16),
                                  onChanged: (v) =>
                                      setState(() => p['paidFor'] = v),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 18),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: 'Đóng góp (VNĐ)',
                                    prefixIcon: Icon(Icons.payments),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 14.0,
                                      horizontal: 12.0,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    final val =
                                        double.tryParse(
                                          v.replaceAll('.', ''),
                                        ) ??
                                        0.0;
                                    setState(() => p['contribution'] = val);
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Đã đóng: ${_fmt((p['contribution'] as num?) ?? 0)} VNĐ',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12.0,
                                      ),
                                      child: Text(
                                        _settlement[p['id']] == null
                                            ? ''
                                            : (_settlement[p['id']]! >= 0
                                                  ? 'Đóng ${_fmt(_settlement[p['id']]!)} VNĐ'
                                                  : 'Nhận ${_fmt(-_settlement[p['id']]!)} VNĐ'),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: _settlement[p['id']] == null
                                              ? null
                                              : (_settlement[p['id']]! >= 0
                                                    ? Colors.red
                                                    : Colors.green),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _calculate,
                            child: const Text('Tính'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveSettlement,
                            child: const Text('Lưu'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lịch sử giao dịch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _history.isEmpty
                  ? const Center(child: Text('Chưa có giao dịch nào'))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final h = _history[i];
                        return Dismissible(
                          key: ValueKey(h['id'] ?? i),
                          direction: DismissDirection.startToEnd,
                          background: Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16.0),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.black54,
                            ),
                          ),
                          confirmDismiss: (dir) async {
                            if (dir == DismissDirection.startToEnd) {
                              final action =
                                  await showModalBottomSheet<String?>(
                                    context: context,
                                    builder: (c) => SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.share),
                                            title: const Text('Chia sẻ'),
                                            onTap: () =>
                                                Navigator.of(c).pop('share'),
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.delete),
                                            title: const Text('Xóa'),
                                            onTap: () =>
                                                Navigator.of(c).pop('delete'),
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.close),
                                            title: const Text('Hủy'),
                                            onTap: () =>
                                                Navigator.of(c).pop(null),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                              if (action == 'share') {
                                final sb = StringBuffer();
                                sb.writeln(
                                  'Tổng: ${_fmt(num.tryParse((h['total'] ?? '').toString()) ?? 0)} VNĐ',
                                );
                                sb.writeln('Ghi chú: ${h['note'] ?? ''}');
                                for (final p in (h['participants'] as List)) {
                                  final contrib =
                                      num.tryParse(
                                        (p['contribution'] ?? '').toString(),
                                      ) ??
                                      0;
                                  final settle =
                                      num.tryParse(
                                        (p['settlement'] ?? '').toString(),
                                      ) ??
                                      0;
                                  final paidFor = (p['paidFor'] ?? '')
                                      .toString();
                                  sb.writeln(
                                    '- ${p['name']}${paidFor.isNotEmpty ? ' ($paidFor)' : ''}: đóng ${_fmt(contrib)} VNĐ, ${settle >= 0 ? 'Đóng ${_fmt(settle)} VNĐ' : 'Nhận ${_fmt(-settle)} VNĐ'}',
                                  );
                                }
                                await _showShareSheet(context, sb.toString());
                                return false;
                              } else if (action == 'delete') {
                                final sure = await showDialog<bool?>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Xác nhận'),
                                    content: const Text(
                                      'Bạn có chắc muốn xóa lịch sử này?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(c).pop(false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(c).pop(true),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                                return sure ?? false;
                              }
                            }
                            return false;
                          },
                          onDismissed: (dir) async {
                            final id = h['id'];
                            _history.removeWhere((e) => e['id'] == id);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setStringList(
                              _historyKey,
                              _history.map((e) => jsonEncode(e)).toList(),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã xóa lịch sử')),
                              );
                            }
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(
                                'Tổng: ${_fmt(num.tryParse((h['total'] ?? '').toString()) ?? 0)} VNĐ',
                              ),
                              subtitle: Text(
                                '${h['note'] ?? ''} • ${h['date'] ?? ''}',
                              ),
                              onTap: () => showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Chi tiết'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                            0.6,
                                      ),
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: (h['participants'] as List).map<Widget>((
                                          p,
                                        ) {
                                          final contrib =
                                              num.tryParse(
                                                (p['contribution'] ?? '')
                                                    .toString(),
                                              ) ??
                                              0;
                                          final settle =
                                              num.tryParse(
                                                (p['settlement'] ?? '')
                                                    .toString(),
                                              ) ??
                                              0;
                                          final paidFor = (p['paidFor'] ?? '')
                                              .toString();
                                          return ListTile(
                                            title: Text(p['name'] ?? ''),
                                            subtitle: Text(
                                              'Đóng góp: ${_fmt(contrib)} VNĐ${paidFor.isNotEmpty ? ' • Trả cho: $paidFor' : ''}',
                                            ),
                                            trailing: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 12.0,
                                              ),
                                              child: Text(
                                                settle >= 0
                                                    ? 'Đóng ${_fmt(settle)} VNĐ'
                                                    : 'Nhận ${_fmt(-settle)} VNĐ',
                                                style: TextStyle(
                                                  color: settle >= 0
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(c).pop(),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
