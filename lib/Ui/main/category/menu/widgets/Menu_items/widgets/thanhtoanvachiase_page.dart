import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class ThanhtoanvachiasePage extends StatefulWidget {
  const ThanhtoanvachiasePage({super.key});

  @override
  State<ThanhtoanvachiasePage> createState() => _ThanhtoanvachiasePageState();
}

enum _SplitMode { equal, custom, percent }

enum _MemberSource { manual, trip }

class _SplitExpense {
  _SplitExpense({
    required this.title,
    required this.amount,
    required this.payer,
    required this.shares,
  });

  final String title;
  final double amount;
  final String payer;
  final Map<String, double> shares;
}

class _ThanhtoanvachiasePageState extends State<ThanhtoanvachiasePage> {
  final FirebaseMenuService _menuService = FirebaseMenuService();
  final List<String> _manualMembers = [];
  final List<_SplitExpense> _expenses = [];

  StreamSubscription<List<TripModel>>? _tripsSubscription;
  List<TripModel> _activeTrips = [];
  String? _selectedTripId;
  List<String> _tripMembers = [];
  _MemberSource _memberSource = _MemberSource.manual;

  List<String> get _members {
    if (_memberSource == _MemberSource.trip) {
      return _tripMembers;
    }
    if (_manualMembers.isEmpty) {
      return [];
    }
    return ['Bạn', ..._manualMembers];
  }

  void _removeManualMember(String member) {
    setState(() => _manualMembers.removeWhere((m) => m == member));
  }

  Widget _buildMemberChip(String member) {
    final isManualMode = _memberSource == _MemberSource.manual;
    final isRemovable = isManualMode && member != 'Bạn';

    if (!isRemovable) {
      return Chip(label: Text(member));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Chip(label: Text(member)),
          Positioned(
            right: -6,
            top: -6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _removeManualMember(member),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadActiveTrips();
  }

  @override
  void dispose() {
    _tripsSubscription?.cancel();
    super.dispose();
  }

  void _loadActiveTrips() {
    _tripsSubscription?.cancel();
    _tripsSubscription = _menuService.getTripsStream().listen((trips) {
      if (!mounted) return;

      final eligibleTrips = trips.where(_isEligibleTrip).toList();

      setState(() {
        _activeTrips = eligibleTrips;
        if (_selectedTripId == null ||
            !_activeTrips.any((trip) => trip.id == _selectedTripId)) {
          _selectedTripId = _activeTrips.isNotEmpty
              ? _activeTrips.first.id
              : null;
        }

        if (_activeTrips.isEmpty && _memberSource == _MemberSource.trip) {
          _memberSource = _MemberSource.manual;
          _tripMembers = [];
        }
      });

      _syncTripMembers();
    });
  }

  bool _isEligibleTrip(TripModel trip) {
    if (trip.status == TripStatus.pending ||
        trip.status == TripStatus.gathering ||
        trip.status == TripStatus.active) {
      return true;
    }

    if (trip.status == TripStatus.completed ||
        trip.status == TripStatus.cancelled) {
      final now = DateTime.now();
      final tripStoppedAt = DateTime(
        trip.endDate.year,
        trip.endDate.month,
        trip.endDate.day,
        23,
        59,
        59,
      );
      final daysFromStop = now.difference(tripStoppedAt).inDays;
      return daysFromStop >= 0 && daysFromStop <= 7;
    }

    return false;
  }

  Future<void> _syncTripMembers() async {
    if (_memberSource != _MemberSource.trip) return;
    final tripId = _selectedTripId;
    if (tripId == null) {
      if (mounted) setState(() => _tripMembers = []);
      return;
    }

    final trip = _activeTrips.where((t) => t.id == tripId).firstOrNull;
    if (trip == null || trip.members.isEmpty) {
      if (mounted) setState(() => _tripMembers = []);
      return;
    }

    final names = await _menuService.getMemberNames(trip.members);
    final currentUserId = _menuService.currentUserId;
    final resolved = trip.members
        .map((memberId) {
          if (memberId == currentUserId) {
            return 'Bạn';
          }
          return (names[memberId] ?? 'Người dùng').trim();
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (!mounted) return;
    setState(() {
      _tripMembers = resolved;
    });
  }

  String _fmtMoney(num value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  Map<String, double> _balances() {
    final result = <String, double>{for (final member in _members) member: 0};

    for (final expense in _expenses) {
      result[expense.payer] = (result[expense.payer] ?? 0) + expense.amount;
      for (final entry in expense.shares.entries) {
        result[entry.key] = (result[entry.key] ?? 0) - entry.value;
      }
    }

    return result;
  }

  List<String> _suggestSettlements() {
    final balances = _balances();
    final debtors = <MapEntry<String, double>>[];
    final creditors = <MapEntry<String, double>>[];

    balances.forEach((name, amount) {
      if (amount < -0.01) {
        debtors.add(MapEntry(name, -amount));
      } else if (amount > 0.01) {
        creditors.add(MapEntry(name, amount));
      }
    });

    final suggestions = <String>[];
    int i = 0;
    int j = 0;
    int guard = 0;
    final maxIterations = debtors.length * creditors.length + 10;
    while (i < debtors.length &&
        j < creditors.length &&
        guard < maxIterations) {
      guard++;
      final debtor = debtors[i];
      final creditor = creditors[j];
      final settled = debtor.value < creditor.value
          ? debtor.value
          : creditor.value;

      if (settled <= 0) {
        break;
      }

      suggestions.add(
        '${debtor.key} tra ${_fmtMoney(settled)} VND cho ${creditor.key}',
      );

      final newDebtorValue = debtor.value - settled;
      final newCreditorValue = creditor.value - settled;

      debtors[i] = MapEntry(debtor.key, newDebtorValue);
      creditors[j] = MapEntry(creditor.key, newCreditorValue);

      if (newDebtorValue <= 0.01) i++;
      if (newCreditorValue <= 0.01) j++;
    }

    return suggestions;
  }

  double get _totalExpense => _expenses.fold(0, (sum, e) => sum + e.amount);

  Future<void> _addMember() async {
    if (_memberSource == _MemberSource.trip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang dùng dữ liệu thành viên từ chuyến đi đã chọn'),
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên thành viên',
            hintText: 'Ví dụ: Cường',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    final cleaned = (name ?? '').trim();
    if (cleaned.isEmpty) return;
    if (cleaned.toLowerCase() == 'ban' || cleaned.toLowerCase() == 'bạn') {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bạn đã có sẵn trong nhóm')));
      return;
    }
    if (_manualMembers.any((m) => m.toLowerCase() == cleaned.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thành viên đã tồn tại')));
      return;
    }

    setState(() => _manualMembers.add(cleaned));
  }

  Future<void> _addExpense() async {
    if (_members.isEmpty) return;

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String payer = _members.first;
    _SplitMode mode = _SplitMode.equal;
    final selectedMembers = <String>{..._members};
    final customControllers = <String, TextEditingController>{
      for (final member in _members) member: TextEditingController(),
    };

    final created = await showModalBottomSheet<_SplitExpense>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setInnerState) {
            final inset = MediaQuery.of(innerContext).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, inset + 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tạo khoản chi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung',
                        hintText: 'Ăn tối, taxi, khách sạn...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền (VND)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: payer,
                      decoration: const InputDecoration(labelText: 'Người trả'),
                      items: _members
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setInnerState(() => payer = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_SplitMode>(
                      segments: const [
                        ButtonSegment(
                          value: _SplitMode.equal,
                          label: Text('Chia đều'),
                          icon: Icon(Icons.balance),
                        ),
                        ButtonSegment(
                          value: _SplitMode.custom,
                          label: Text('Chia tay'),
                          icon: Icon(Icons.tune),
                        ),
                        ButtonSegment(
                          value: _SplitMode.percent,
                          label: Text('Chia %'),
                          icon: Icon(Icons.percent),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) {
                        setInnerState(() => mode = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Người tham gia',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _members.map((member) {
                        return FilterChip(
                          label: Text(member),
                          selected: selectedMembers.contains(member),
                          onSelected: (selected) {
                            setInnerState(() {
                              if (selected) {
                                selectedMembers.add(member);
                              } else {
                                selectedMembers.remove(member);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (mode == _SplitMode.custom ||
                        mode == _SplitMode.percent) ...[
                      const SizedBox(height: 12),
                      Text(
                        mode == _SplitMode.custom
                            ? 'Nhập số tiền từng người'
                            : 'Nhập phần trăm từng người',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...selectedMembers.map((member) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: customControllers[member],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: member,
                              suffixText: mode == _SplitMode.custom
                                  ? 'VND'
                                  : '%',
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Lưu khoản chi'),
                        onPressed: () {
                          final amount =
                              double.tryParse(amountController.text.trim()) ??
                              0;
                          final title = titleController.text.trim().isEmpty
                              ? 'Khoản chi mới'
                              : titleController.text.trim();

                          if (amount <= 0) {
                            ScaffoldMessenger.of(innerContext).showSnackBar(
                              const SnackBar(content: Text('Số tiền phải > 0')),
                            );
                            return;
                          }
                          if (selectedMembers.isEmpty) {
                            ScaffoldMessenger.of(innerContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cần chọn ít nhất 1 người tham gia',
                                ),
                              ),
                            );
                            return;
                          }

                          final shares = <String, double>{};
                          if (mode == _SplitMode.equal) {
                            final perHead = amount / selectedMembers.length;
                            for (final member in selectedMembers) {
                              shares[member] = perHead;
                            }
                          } else if (mode == _SplitMode.custom) {
                            double sum = 0;
                            for (final member in selectedMembers) {
                              final value =
                                  double.tryParse(
                                    customControllers[member]?.text.trim() ??
                                        '',
                                  ) ??
                                  0;
                              shares[member] = value;
                              sum += value;
                            }

                            if ((sum - amount).abs() > 1) {
                              ScaffoldMessenger.of(innerContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tổng chia (${_fmtMoney(sum)}) phải bằng số tiền (${_fmtMoney(amount)})',
                                  ),
                                ),
                              );
                              return;
                            }
                          } else {
                            double percentSum = 0;
                            for (final member in selectedMembers) {
                              final percentValue =
                                  double.tryParse(
                                    customControllers[member]?.text.trim() ??
                                        '',
                                  ) ??
                                  0;
                              shares[member] = amount * percentValue / 100;
                              percentSum += percentValue;
                            }

                            if ((percentSum - 100).abs() > 0.1) {
                              ScaffoldMessenger.of(innerContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tổng phần trăm (${percentSum.toStringAsFixed(2)}%) phải bằng 100%',
                                  ),
                                ),
                              );
                              return;
                            }
                          }

                          Navigator.of(sheetContext).pop(
                            _SplitExpense(
                              title: title,
                              amount: amount,
                              payer: payer,
                              shares: shares,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    for (final controller in customControllers.values) {
      controller.dispose();
    }
    titleController.dispose();
    amountController.dispose();

    if (created == null) return;
    setState(() => _expenses.insert(0, created));
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balances();
    final settlements = _suggestSettlements();

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán và chia sẻ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Thêm khoản chi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhóm chia tiền',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<_MemberSource>(
                    segments: const [
                      ButtonSegment<_MemberSource>(
                        value: _MemberSource.manual,
                        label: Text('Nhập riêng'),
                        icon: Icon(Icons.edit_note),
                      ),
                      ButtonSegment<_MemberSource>(
                        value: _MemberSource.trip,
                        label: Text('Từ chuyến đi'),
                        icon: Icon(Icons.luggage),
                      ),
                    ],
                    selected: {_memberSource},
                    onSelectionChanged: (selection) async {
                      final selected = selection.first;
                      if (selected == _MemberSource.trip &&
                          _activeTrips.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Không có chuyến đi phù hợp (đang hoạt động hoặc đã dừng <= 7 ngày)',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _memberSource = selected;
                      });
                      await _syncTripMembers();
                    },
                  ),
                  if (_memberSource == _MemberSource.trip) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn chuyến đi',
                      ),
                      items: _activeTrips
                          .map(
                            (trip) => DropdownMenuItem<String>(
                              value: trip.id,
                              child: Text(trip.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _selectedTripId = value);
                        await _syncTripMembers();
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members.map(_buildMemberChip).toList(),
                  ),
                  if (_memberSource == _MemberSource.manual) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _addMember,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Thêm thành viên'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng chi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_fmtMoney(_totalExpense)} VND',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Số dư từng người',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._members.map((member) {
                    final amount = balances[member] ?? 0;
                    final isPositive = amount > 0.01;
                    final isNegative = amount < -0.01;
                    final color = isPositive
                        ? Colors.green
                        : (isNegative ? Colors.red : Colors.grey.shade700);
                    final prefix = isPositive ? '+' : '';

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey.shade50,
                        child: Text(member.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(member),
                      subtitle: Text(
                        isPositive
                            ? 'Được nhận'
                            : (isNegative ? 'Cần trả' : 'Cân bằng'),
                      ),
                      trailing: Text(
                        '$prefix${_fmtMoney(amount)} VND',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                  if (settlements.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Gợi ý thanh toán',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...settlements.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('- $line'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Lịch sử khoản chi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_expenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: const Text(
                'Chưa có khoản chi nào. Bấm "Thêm khoản chi" để bắt đầu.',
              ),
            )
          else
            ..._expenses.map((expense) {
              final splitText = expense.shares.entries
                  .map((e) => '${e.key}: ${_fmtMoney(e.value)}')
                  .join(' | ');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(expense.title),
                  subtitle: Text(
                    'Người trả: ${expense.payer}\nChia: $splitText',
                  ),
                  trailing: Text(
                    '${_fmtMoney(expense.amount)} VND',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
