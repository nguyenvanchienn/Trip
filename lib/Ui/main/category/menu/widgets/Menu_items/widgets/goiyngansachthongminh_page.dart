import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String _type = 'Standard'; // Economy, Standard, Premium
  Map<String, double> _result = {};
  bool _loadingPresets = true;
  List<Map<String, dynamic>> _presets = [];

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
    _type = p['type'] ?? 'Standard';
    _calculate();
  }

  void _calculate() {
    final total =
        double.tryParse(_budgetCtrl.text.replaceAll('.', '').trim()) ?? 0;
    final days = int.tryParse(_daysCtrl.text.trim()) ?? 1;
    final people = int.tryParse(_peopleCtrl.text.trim()) ?? 1;

    if (total <= 0 || days <= 0 || people <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số hợp lệ')));
      return;
    }

    // Percentages changes by type
    Map<String, double> pct;
    if (_type == 'Economy') {
      pct = {
        'Accomodation': 0.35,
        'Food': 0.30,
        'Transport': 0.20,
        'Misc': 0.15,
      };
    } else if (_type == 'Premium') {
      pct = {
        'Accomodation': 0.45,
        'Food': 0.30,
        'Transport': 0.15,
        'Misc': 0.10,
      };
    } else {
      pct = {
        'Accomodation': 0.40,
        'Food': 0.30,
        'Transport': 0.20,
        'Misc': 0.10,
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
    res['Type'] = _type == 'Economy'
        ? 0
        : (_type == 'Standard' ? 1 : 2).toDouble();

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

  String _fmt(double v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý ngân sách thông minh')),
      body: Padding(
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
                ChoiceChip(
                  label: const Text('Economy'),
                  selected: _type == 'Economy',
                  onSelected: (_) => setState(() => _type = 'Economy'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Standard'),
                  selected: _type == 'Standard',
                  onSelected: (_) => setState(() => _type = 'Standard'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Premium'),
                  selected: _type == 'Premium',
                  onSelected: (_) => setState(() => _type = 'Premium'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Gợi ý'),
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

            const SizedBox(height: 12),
            const Text(
              'Preset đã lưu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingPresets
                  ? const Center(child: CircularProgressIndicator())
                  : _presets.isEmpty
                  ? const Center(child: Text('Chưa có preset nào'))
                  : ListView.separated(
                      itemCount: _presets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final p = _presets[i];
                        final title =
                            'Tổng ${p['total']} - ${p['days']} ngày - ${p['people']} người - ${p['type']}';
                        return ListTile(
                          leading: const Icon(Icons.save),
                          title: Text(title),
                          subtitle: Text('Lưu: ${p['createdAt'] ?? ''}'),
                          onTap: () => _applyPreset(p),
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
