import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final String _historyKey = 'phuongtiendichuyen_history_v1';
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _displayed = [];
  bool _selectionMode = false;
  final Set<String> _selected = <String>{};
  Set<String> _activeFilter = <String>{};
  DateTime? _filterFrom;
  DateTime? _filterTo;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    final parsed = raw
        .map((s) {
          try {
            final d = jsonDecode(s);
            if (d is Map<String, dynamic>) return d;
            if (d is Map) return Map<String, dynamic>.from(d);
          } catch (_) {}
          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();
    setState(() {
      _history = parsed;
      _applyFilter(_activeFilter); // updates _displayed
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() {
      _history = [];
      _displayed = [];
      _selectionMode = false;
      _selected.clear();
      _activeFilter.clear();
      _filterFrom = null;
      _filterTo = null;
    });
  }

  // Delete a single record by timestamp or JSON match
  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    String? ts = record['timestamp']?.toString();
    bool removed = false;
    if (ts != null) {
      for (var i = raw.length - 1; i >= 0; i--) {
        try {
          final d = jsonDecode(raw[i]);
          if ((d is Map && d['timestamp']?.toString() == ts) ||
              raw[i] == jsonEncode(record)) {
            raw.removeAt(i);
            removed = true;
            break;
          }
        } catch (_) {}
      }
    }
    if (!removed) {
      raw.remove(jsonEncode(record));
    }
    await prefs.setStringList(_historyKey, raw);
    await _loadHistory();
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    raw.removeWhere((s) {
      try {
        final d = jsonDecode(s);
        return _selected.contains(d['timestamp']?.toString());
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_historyKey, raw);
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
    await _loadHistory();
  }

  void _toggleSelection(String ts) {
    setState(() {
      if (!_selected.remove(ts)) {
        _selected.add(ts);
      }
    });
  }

  void _applyFilter(Set<String> types, {DateTime? from, DateTime? to}) {
    setState(() {
      _activeFilter = Set<String>.from(types);
      _filterFrom = from;
      _filterTo = to;
      _displayed = _history.where((r) {
        final t = (r['type'] ?? '') as String;
        if (_activeFilter.isNotEmpty && !_activeFilter.contains(t)) {
          return false;
        }
        if (_filterFrom != null || _filterTo != null) {
          final ts = r['timestamp']?.toString();
          if (ts == null || ts.isEmpty) return false;
          try {
            final dt = DateTime.parse(ts).toLocal();
            if (_filterFrom != null) {
              final start = DateTime(
                _filterFrom!.year,
                _filterFrom!.month,
                _filterFrom!.day,
              );
              if (dt.isBefore(start)) return false;
            }
            if (_filterTo != null) {
              final end = DateTime(
                _filterTo!.year,
                _filterTo!.month,
                _filterTo!.day,
                23,
                59,
                59,
              );
              if (dt.isAfter(end)) return false;
            }
          } catch (_) {
            return false;
          }
        }
        return true;
      }).toList();
      _selectionMode = false;
      _selected.clear();
    });
  }

  Future<void> _showFilterDialog() async {
    final allTypes = <String>{
      'Xe buýt',
      'Xe khách',
      'Taxi',
      'Ô tô',
      'Tàu hỏa',
      'Máy bay',
      'Xe đạp',
      'Xe máy',
    };
    final selected = Set<String>.from(_activeFilter);
    DateTime? selFrom = _filterFrom;
    DateTime? selTo = _filterTo;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: const Text('Lọc lịch sử'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date controls at the top so they're visible without scrolling
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Khoảng ngày',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final now = DateTime.now();
                        setStateDialog(() {
                          selFrom = DateTime(now.year, now.month, now.day);
                          selTo = selFrom;
                        });
                      },
                      child: const Text('Hôm nay'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final now = DateTime.now();
                        setStateDialog(() {
                          selFrom = DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ).subtract(const Duration(days: 6));
                          selTo = DateTime(now.year, now.month, now.day);
                        });
                      },
                      child: const Text('7 ngày'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final now = DateTime.now();
                        setStateDialog(() {
                          selFrom = DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ).subtract(const Duration(days: 29));
                          selTo = DateTime(now.year, now.month, now.day);
                        });
                      },
                      child: const Text('30 ngày'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final r = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDateRange: (selFrom != null && selTo != null)
                              ? DateTimeRange(start: selFrom!, end: selTo!)
                              : null,
                        );
                        if (r != null) {
                          setStateDialog(() {
                            selFrom = r.start;
                            selTo = r.end;
                          });
                        }
                      },
                      child: const Text('Chọn ngày...'),
                    ),
                    Chip(
                      label: Text(
                        selFrom == null
                            ? 'Không có'
                            : '${_formatShortDate(selFrom!)} — ${_formatShortDate(selTo!)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Loại phương tiện',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...allTypes.map(
                  (t) => CheckboxListTile(
                    value: selected.contains(t),
                    onChanged: (v) => setStateDialog(() {
                      if (v == true) {
                        selected.add(t);
                      } else {
                        selected.remove(t);
                      }
                    }),
                    title: Text(t),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      DateTime? from;
      DateTime? to;
      if (selFrom != null) {
        from = DateTime(selFrom!.year, selFrom!.month, selFrom!.day);
      }
      if (selTo != null) to = DateTime(selTo!.year, selTo!.month, selTo!.day);
      _applyFilter(selected, from: from, to: to);
    }
  }

  String _fmtNum(num? v) {
    if (v == null) return '';
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')} ₫';
  }

  IconData _iconForType(String t) {
    switch (t) {
      case 'Xe buýt':
        return Icons.directions_bus_filled;
      case 'Xe khách':
        return Icons.chair;
      case 'Taxi':
        return Icons.local_taxi;
      case 'Ô tô':
        return Icons.directions_car_filled;
      case 'Tàu hỏa':
        return Icons.train;
      case 'Máy bay':
        return Icons.flight;
      case 'Xe đạp':
        return Icons.pedal_bike;
      case 'Xe máy':
        return Icons.motorcycle;
      default:
        return Icons.history;
    }
  }

  String _formatShortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selected.length} đang chọn')
            : const Text('Lịch sử đặt vé'),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selected.clear();
                }),
              )
            : null,
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selected.isEmpty
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Xóa mục đã chọn'),
                              content: Text(
                                'Bạn có chắc muốn xóa ${_selected.length} mục đã chọn?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await _deleteSelected();
                        },
                ),
              ]
            : [
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'select') {
                      setState(() {
                        _selectionMode = true;
                        _selected.clear();
                      });
                    } else if (v == 'filter') {
                      await _showFilterDialog();
                    } else if (v == 'clear') {
                      final ok = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Xóa lịch sử'),
                          content: const Text(
                            'Bạn có chắc muốn xóa tất cả lịch sử?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) await _clearHistory();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'select', child: Text('Chọn nhiều')),
                    PopupMenuItem(value: 'filter', child: Text('Lọc lịch')),
                    PopupMenuItem(value: 'clear', child: Text('Xóa tất cả')),
                  ],
                ),
              ],
      ),
      body: _displayed.isEmpty
          ? const Center(child: Text('Chưa có lịch sử đặt vé'))
          : Column(
              children: [
                if (_activeFilter.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _activeFilter.map((f) {
                        return Chip(
                          label: Text(f),
                          onDeleted: () {
                            final newSet = Set<String>.from(_activeFilter);
                            newSet.remove(f);
                            _applyFilter(newSet);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _displayed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = _displayed[i];
                      final t = (r['type'] ?? '') as String;
                      final title =
                          r['route'] ?? r['model'] ?? r['station'] ?? t;
                      final ts = (r['timestamp'] ?? '').toString();
                      String subtitle = ts;
                      if (ts.isNotEmpty) {
                        try {
                          subtitle = DateTime.parse(
                            ts,
                          ).toLocal().toString().split('.').first;
                        } catch (_) {}
                      }
                      String trailing = '';
                      if (r.containsKey('total')) {
                        trailing = _fmtNum(r['total']);
                      } else if (r.containsKey('price'))
                        trailing = _fmtNum(r['price']);

                      return Dismissible(
                        key: ValueKey(ts.isNotEmpty ? ts : i.toString()),
                        direction: _selectionMode
                            ? DismissDirection.none
                            : DismissDirection.startToEnd,
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Xóa mục'),
                              content: const Text(
                                'Bạn có chắc muốn xóa mục này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _deleteRecord(r);
                          }
                          return ok == true;
                        },
                        child: Card(
                          child: ListTile(
                            leading: _selectionMode
                                ? Checkbox(
                                    value: _selected.contains(ts),
                                    onChanged: (_) => _toggleSelection(ts),
                                  )
                                : Icon(_iconForType(t)),
                            title: Text('$t • $title'),
                            subtitle: Text(subtitle),
                            trailing: trailing.isEmpty
                                ? null
                                : Text(
                                    trailing,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            selected: _selectionMode && _selected.contains(ts),
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelection(ts);
                                return;
                              }
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(t),
                                  content: SingleChildScrollView(
                                    child: Text(
                                      const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(r),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
