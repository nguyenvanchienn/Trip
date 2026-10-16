import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/data/services/trip_ai_service.dart';

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

class GoiYNganSachThongMinhPage extends StatefulWidget {
  const GoiYNganSachThongMinhPage({super.key});

  @override
  State<GoiYNganSachThongMinhPage> createState() =>
      _GoiYNganSachThongMinhPageState();
}

class _GoiYNganSachThongMinhPageState extends State<GoiYNganSachThongMinhPage> {
  final _budgetCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '1');
  final _peopleCtrl = TextEditingController(text: '1');

  String _type = 'Tiêu chuẩn'; // Tiết kiệm, Tiêu chuẩn, Cao cấp
  Map<String, double> _result = {};
  bool _loadingPresets = true;
  List<Map<String, dynamic>> _presets = [];

  // AI suggestion state
  bool _loadingAI = false;
  String _aiSuggestion = '';
  final _departureCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  final String _presetKey = 'budget_presets_v1';

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _daysCtrl.dispose();
    _peopleCtrl.dispose();
    _departureCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_presetKey) ?? [];
    _presets = raw
        .map((s) {
          try {
            final decoded = jsonDecode(s);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
            return <String, dynamic>{};
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();
    setState(() => _loadingPresets = false);
  }

  Future<void> _savePreset(Map<String, dynamic> p) async {
    final prefs = await SharedPreferences.getInstance();
    _presets.insert(0, p);
    final raw = _presets.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_presetKey, raw);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu preset')));
  }

  void _applyPreset(Map<String, dynamic> p) {
    _budgetCtrl.text = (p['total'] ?? '').toString();
    _daysCtrl.text = (p['days'] ?? '1').toString();
    _peopleCtrl.text = (p['people'] ?? '1').toString();
    _departureCtrl.text = p['departure'] ?? '';
    _destinationCtrl.text = p['destination'] ?? '';
    // Convert old English type names to Vietnamese
    final typeValue = p['type'] ?? 'Tiêu chuẩn';
    if (typeValue == 'Economy') {
      _type = 'Tiết kiệm';
    } else if (typeValue == 'Standard') {
      _type = 'Tiêu chuẩn';
    } else if (typeValue == 'Premium') {
      _type = 'Cao cấp';
    } else {
      _type = typeValue;
    }
    _calculate();
  }

  void _calculate() {
    // Check if required fields are empty
    if (_budgetCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tổng ngân sách')),
      );
      return;
    }
    if (_daysCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số ngày')));
      return;
    }
    if (_peopleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số người')));
      return;
    }

    final total =
        double.tryParse(_budgetCtrl.text.replaceAll('.', '').trim()) ?? 0;
    final days = int.tryParse(_daysCtrl.text.trim()) ?? 0;
    final people = int.tryParse(_peopleCtrl.text.trim()) ?? 0;

    if (total <= 0 || days <= 0 || people <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số hợp lệ (lớn hơn 0)')),
      );
      return;
    }

    // Percentages changes by type
    Map<String, double> pct;
    if (_type == 'Tiết kiệm') {
      pct = {
        'Chỗ ở': 0.35,
        'Ăn uống': 0.30,
        'Di chuyển': 0.20,
        'Chi phí khác': 0.15,
      };
    } else if (_type == 'Cao cấp') {
      pct = {
        'Chỗ ở': 0.45,
        'Ăn uống': 0.30,
        'Di chuyển': 0.15,
        'Chi phí khác': 0.10,
      };
    } else {
      pct = {
        'Chỗ ở': 0.40,
        'Ăn uống': 0.30,
        'Di chuyển': 0.20,
        'Chi phí khác': 0.10,
      };
    }

    final Map<String, double> res = {};
    pct.forEach((k, v) {
      res[k] = double.parse((total * v).toStringAsFixed(0));
    });

    res['PerPersonPerDay'] = double.parse(
      (total / people / days).toStringAsFixed(0),
    );
    res['Total'] = total;
    res['Days'] = days.toDouble();
    res['People'] = people.toDouble();
    res['Type'] = _type == 'Tiết kiệm'
        ? 0
        : (_type == 'Tiêu chuẩn' ? 1 : 2).toDouble();

    setState(() {
      _result = res;
    });
  }

  Future<void> _copyResult() async {
    if (_result.isEmpty) return;
    final sb = StringBuffer();
    sb.writeln('Gợi ý ngân sách: Tổng ${_result['Total']} - $_type');
    sb.writeln('Mỗi người / ngày: ${_result['PerPersonPerDay']}');
    _result.forEach((k, v) {
      if (!['Total', 'PerPersonPerDay', 'Days', 'People', 'Type'].contains(k)) {
        sb.writeln('- $k: ${v.toStringAsFixed(0)}');
      }
    });
    await Clipboard.setData(ClipboardData(text: sb.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép kết quả')));
  }

  Future<void> _getAISuggestion() async {
    // Validate all required fields
    if (_budgetCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tổng ngân sách')),
      );
      return;
    }
    if (_daysCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số ngày')));
      return;
    }
    if (_peopleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số người')));
      return;
    }
    if (_destinationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập điểm đến để AI gợi ý chính xác hơn'),
        ),
      );
      return;
    }

    final total =
        double.tryParse(_budgetCtrl.text.replaceAll('.', '').trim()) ?? 0;
    final days = int.tryParse(_daysCtrl.text.trim()) ?? 0;
    final people = int.tryParse(_peopleCtrl.text.trim()) ?? 0;

    if (total <= 0 || days <= 0 || people <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số hợp lệ (lớn hơn 0)')),
      );
      return;
    }

    setState(() {
      _loadingAI = true;
      _aiSuggestion = '';
    });

    try {
      final result = await TripAiService.getBudgetCalculation(
        totalBudget: total,
        days: days,
        people: people,
        tripType: _type,
        departure: _departureCtrl.text.trim().isNotEmpty
            ? _departureCtrl.text.trim()
            : null,
        destination: _destinationCtrl.text.trim(),
      );

      if (mounted) {
        final budget = result['budget'] as Map<String, double>? ?? {};

        setState(() {
          // Fill result table with AI calculation
          _result = {
            ...budget,
            'Total': total,
            'Days': days.toDouble(),
            'People': people.toDouble(),
            'PerPersonPerDay':
                result['perPersonPerDay'] as double? ?? (total / people / days),
            'Type': _type == 'Tiết kiệm'
                ? 0
                : (_type == 'Tiêu chuẩn' ? 1 : 2).toDouble(),
          };
          _aiSuggestion = result['suggestion'] as String? ?? '';
          _loadingAI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSuggestion = 'Có lỗi xảy ra: $e';
          _loadingAI = false;
        });
      }
    }
  }

  String _fmt(double v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý ngân sách thông minh')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Tổng ngân sách (VNĐ)',
                prefixIcon: Icon(Icons.payments),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số ngày',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _peopleCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số người',
                      prefixIcon: Icon(Icons.group),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _departureCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Điểm đi',
                      prefixIcon: Icon(Icons.flight_takeoff),
                      hintText: 'VD: Hà Nội, TP.HCM...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _destinationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Điểm đến',
                      prefixIcon: Icon(Icons.flight_land),
                      hintText: 'VD: Đà Lạt, Phú Quốc...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Tiết kiệm'),
                  selected: _type == 'Tiết kiệm',
                  onSelected: (_) => setState(() => _type = 'Tiết kiệm'),
                ),
                ChoiceChip(
                  label: const Text('Tiêu chuẩn'),
                  selected: _type == 'Tiêu chuẩn',
                  onSelected: (_) => setState(() => _type = 'Tiêu chuẩn'),
                ),
                ChoiceChip(
                  label: const Text('Cao cấp'),
                  selected: _type == 'Cao cấp',
                  onSelected: (_) => setState(() => _type = 'Cao cấp'),
                ),
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Tính toán'),
                ),
                ElevatedButton.icon(
                  onPressed: _loadingAI ? null : _getAISuggestion,
                  icon: _loadingAI
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset(
                          'asset/icon/logo.png',
                          width: 20,
                          height: 20,
                        ),
                  label: Text(_loadingAI ? 'Đang xử lý...' : 'Trip AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_result.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kết quả',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Tổng: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${_fmt(_result['Total'] ?? 0)} VNĐ'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Mỗi người / ngày: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${_fmt(_result['PerPersonPerDay'] ?? 0)} VNĐ'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._result.entries
                          .where(
                            (e) => ![
                              'Total',
                              'PerPersonPerDay',
                              'Days',
                              'People',
                              'Type',
                            ].contains(e.key),
                          )
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key),
                                  Text('${_fmt(e.value)} VNĐ'),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _copyResult,
                            child: const Text('Sao chép'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final preset = {
                                'total': _result['Total'],
                                'days': _result['Days']?.toInt() ?? 1,
                                'people': _result['People']?.toInt() ?? 1,
                                'type': _type,
                                'departure': _departureCtrl.text.trim(),
                                'destination': _destinationCtrl.text.trim(),
                                'accommodation': _result['Chỗ ở'],
                                'food': _result['Ăn uống'],
                                'transport': _result['Di chuyển'],
                                'misc': _result['Chi phí khác'],
                                'perPersonPerDay': _result['PerPersonPerDay'],
                                'createdAt': DateTime.now().toIso8601String(),
                              };
                              _savePreset(preset);
                            },
                            child: const Text('Lưu preset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // AI Suggestion Section
            if (_loadingAI) ...[
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Trip AI đang phân tích...'),
                    ],
                  ),
                ),
              ),
            ],

            if (_aiSuggestion.isNotEmpty && !_loadingAI) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'asset/icon/logo.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trip AI gợi ý',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _aiSuggestion = ''),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _aiSuggestion,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _aiSuggestion),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép gợi ý AI'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Sao chép'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Ngân sách đã lưu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (_presets.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Xoá tất cả?'),
                          content: const Text(
                            'Bạn có chắc muốn xoá tất cả preset đã lưu?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Huỷ'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text(
                                'Xoá',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove(_presetKey);
                        setState(() => _presets.clear());
                      }
                    },
                    child: const Text(
                      'Xoá tất cả',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _loadingPresets
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _presets.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Chưa có ngân sách nào được lưu'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final p = _presets[i];
                      final total = p['total'] ?? 0;
                      final totalStr = _fmt(
                        total is double ? total : (total as num).toDouble(),
                      );
                      final departure = p['departure'] ?? '';
                      final destination = p['destination'] ?? '';
                      final route =
                          departure.isNotEmpty && destination.isNotEmpty
                          ? '$departure → $destination'
                          : (destination.isNotEmpty
                                ? destination
                                : (departure.isNotEmpty ? departure : ''));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTypeColor(p['type']),
                            child: const Icon(
                              Icons.savings,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '$totalStr VNĐ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p['days'] ?? 1} ngày • ${p['people'] ?? 1} người • ${_getTypeDisplayName(p['type'])}',
                              ),
                              if (route.isNotEmpty)
                                Text(
                                  route,
                                  style: const TextStyle(color: Colors.blue),
                                ),
                            ],
                          ),
                          isThreeLine: route.isNotEmpty,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'apply') {
                                _applyPreset(p);
                              } else if (action == 'delete') {
                                setState(() => _presets.removeAt(i));
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final raw = _presets
                                    .map((e) => jsonEncode(e))
                                    .toList();
                                await prefs.setStringList(_presetKey, raw);
                              }
                            },
                            itemBuilder: (c) => [
                              const PopupMenuItem(
                                value: 'apply',
                                child: Text('Áp dụng'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Xoá',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _applyPreset(p),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'Tiết kiệm':
      case 'Economy':
        return Colors.green;
      case 'Cao cấp':
      case 'Premium':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getTypeDisplayName(String? type) {
    switch (type) {
      case 'Economy':
        return 'Tiết kiệm';
      case 'Standard':
        return 'Tiêu chuẩn';
      case 'Premium':
        return 'Cao cấp';
      default:
        return type ?? 'Tiêu chuẩn';
    }
  }
}
