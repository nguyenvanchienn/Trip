import 'package:fl_chart/fl_chart.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class DoanhThuPage extends StatefulWidget {
  const DoanhThuPage({super.key});

  @override
  State<DoanhThuPage> createState() => _DoanhThuPageState();
}

class _DoanhThuPageState extends State<DoanhThuPage> {
  _TimeFilter _selectedFilter = _TimeFilter.day;
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  static const Color _chartBg = Colors.white;
  static const Color _chartPanel = Colors.white;
  static const Color _gridColor = Color(0xFFDFE3EB);
  static const Color _axisText = Color(0xFF56606E);
  static const Color _revenueColor = Color(0xFF4E86E6);
  static const Color _titleText = Color(0xFF1B1F2A);

  @override
  void initState() {
    super.initState();
    _selectedRange = _rangeForFilter(_selectedFilter, DateTime.now());
  }

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  String _getPaymentMethodName(String? method) {
    if (method == null || method.trim().isEmpty) return 'Khác';
    final m = method.toLowerCase();
    if (m.contains('trip')) return 'TripPay';
    if (m.contains('zalo')) return 'ZaloPay';
    if (m.contains('bank') || m.contains('ngân hàng') || m.contains('atm')) {
      return 'Ngân hàng liên kết';
    }
    if (m.contains('cod') ||
        m.contains('tiền mặt') ||
        m.contains('nhận hàng')) {
      return 'Thanh toán khi nhận hàng';
    }
    // Nếu method trong DB đang lưu tiếng Việt chuẩn rồi (ví dụ "Ví TripPay") thì lấy luôn hoặc tuỳ chỉnh
    return method;
  }

  Map<String, double> _paymentChannels(
    List<Map<String, dynamic>> list,
    DateTimeRange range,
  ) {
    final rangeStart = _startOfDay(range.start);
    final rangeEnd = _endOfDay(range.end);

    final Map<String, double> totals = {};
    for (final b in list) {
      final status = b['status'] as String? ?? '';
      final s = status.toLowerCase();
      if (s == 'cancelled' ||
          s == 'đã huỷ' ||
          s == 'huỷ' ||
          s == 'hủy' ||
          s == 'đã hủy')
        continue;

      final date = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (date.isBefore(rangeStart) || date.isAfter(rangeEnd)) continue;

      final payment = b['metadata']?['payment'] as Map<String, dynamic>?;
      String? methodStr = payment?['method'] as String?;
      
      // Fallback: extract from item name if metadata doesn't exist
      if (methodStr == null) {
        final items = b['items'] as List<dynamic>? ?? [];
        for (final i in items) {
          if (i is Map) {
            final name = i['name'] as String? ?? '';
            final match = RegExp(r'- Thanh toán:\s*(.*)').firstMatch(name);
            if (match != null) {
              methodStr = match.group(1)?.trim();
              break;
            }
          }
        }
      }
      final method = _getPaymentMethodName(methodStr);
      totals[method] =
          (totals[method] ?? 0) + ((b['totalPrice'] as num?)?.toDouble() ?? 0);
    }
    return totals;
  }

  _TimeSeries _buildSeries(
    List<Map<String, dynamic>> list,
    _TimeFilter filter,
    DateTimeRange range,
  ) {
    if (filter == _TimeFilter.day &&
        _startOfDay(range.start).isBefore(_startOfDay(range.end))) {
      filter = _TimeFilter.week;
    }
    final notCancelled = list.where((b) {
      final status = b['status'] as String? ?? '';
      final s = status.toLowerCase();
      return s != 'cancelled' &&
          s != 'đã huỷ' &&
          s != 'huỷ' &&
          s != 'hủy' &&
          s != 'đã hủy';
    }).toList();
    if (notCancelled.isEmpty) {
      return _TimeSeries([], [], filter);
    }

    final rangeStart = _startOfDay(range.start);
    final rangeEnd = _endOfDay(range.end);
    final ranged = notCancelled.where((b) {
      final date = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
    }).toList();
    if (ranged.isEmpty) {
      return _buildEmptySeries(filter, range);
    }

    DateTime cursor;
    DateTime end;
    switch (filter) {
      case _TimeFilter.day:
        cursor = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
          0,
        );
        end = DateTime(range.end.year, range.end.month, range.end.day, 23);
        break;
      case _TimeFilter.week:
        cursor = DateTime(range.start.year, range.start.month, range.start.day);
        end = DateTime(range.end.year, range.end.month, range.end.day);
        break;
      case _TimeFilter.month:
        cursor = _startOfWeek(range.start);
        end = _startOfWeek(range.end);
        break;
      case _TimeFilter.year:
        cursor = DateTime(range.start.year, range.start.month);
        end = DateTime(range.end.year, range.end.month);
        break;
    }

    final slots = <DateTime>[];
    while (!cursor.isAfter(end)) {
      slots.add(cursor);
      switch (filter) {
        case _TimeFilter.day:
          cursor = DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            cursor.hour + 1,
          );
          break;
        case _TimeFilter.week:
          cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
          break;
        case _TimeFilter.month:
          cursor = cursor.add(const Duration(days: 7));
          break;
        case _TimeFilter.year:
          cursor = DateTime(cursor.year, cursor.month + 1);
          break;
      }
    }

    final visibleSlots = slots;

    final revenue = List<double>.filled(visibleSlots.length, 0.0);

    for (final b in ranged) {
      final date =
          (b['completedAt'] as Timestamp?)?.toDate() ??
          (b['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now();
      final slotKey = _toSlotKey(date, filter);
      final idx = visibleSlots.indexWhere(
        (s) => _isSameSlot(s, slotKey, filter),
      );
      if (idx == -1) continue;
      revenue[idx] += (b['totalPrice'] as num?)?.toDouble() ?? 0;
    }

    return _TimeSeries(visibleSlots, revenue, filter);
  }

  _TimeSeries _buildEmptySeries(_TimeFilter filter, DateTimeRange range) {
    if (filter == _TimeFilter.day &&
        _startOfDay(range.start).isBefore(_startOfDay(range.end))) {
      filter = _TimeFilter.week;
    }
    DateTime cursor;
    DateTime end;
    switch (filter) {
      case _TimeFilter.day:
        cursor = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
          0,
        );
        end = DateTime(range.end.year, range.end.month, range.end.day, 23);
        break;
      case _TimeFilter.week:
        cursor = DateTime(range.start.year, range.start.month, range.start.day);
        end = DateTime(range.end.year, range.end.month, range.end.day);
        break;
      case _TimeFilter.month:
        cursor = _startOfWeek(range.start);
        end = _startOfWeek(range.end);
        break;
      case _TimeFilter.year:
        cursor = DateTime(range.start.year, range.start.month);
        end = DateTime(range.end.year, range.end.month);
        break;
    }

    final labels = <DateTime>[];
    while (!cursor.isAfter(end)) {
      labels.add(cursor);
      switch (filter) {
        case _TimeFilter.day:
          cursor = DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            cursor.hour + 1,
          );
          break;
        case _TimeFilter.week:
          cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
          break;
        case _TimeFilter.month:
          cursor = cursor.add(const Duration(days: 7));
          break;
        case _TimeFilter.year:
          cursor = DateTime(cursor.year, cursor.month + 1);
          break;
      }
    }
    return _TimeSeries(labels, List<double>.filled(labels.length, 0.0), filter);
  }

  DateTime _toSlotKey(DateTime date, _TimeFilter filter) {
    switch (filter) {
      case _TimeFilter.day:
        return DateTime(date.year, date.month, date.day, date.hour);
      case _TimeFilter.week:
        return DateTime(date.year, date.month, date.day);
      case _TimeFilter.month:
        return _startOfWeek(date);
      case _TimeFilter.year:
        return DateTime(date.year, date.month);
    }
  }

  bool _isSameSlot(DateTime a, DateTime b, _TimeFilter filter) {
    switch (filter) {
      case _TimeFilter.day:
        return a.year == b.year &&
            a.month == b.month &&
            a.day == b.day &&
            a.hour == b.hour;
      case _TimeFilter.week:
        return a.year == b.year && a.month == b.month && a.day == b.day;
      case _TimeFilter.month:
        final startA = _startOfWeek(a);
        final startB = _startOfWeek(b);
        return startA.year == startB.year &&
            startA.month == startB.month &&
            startA.day == startB.day;
      case _TimeFilter.year:
        return a.year == b.year && a.month == b.month;
    }
  }

  String _formatSlotLabel(DateTime d, _TimeFilter filter) {
    final m = d.month.toString().padLeft(2, '0');
    switch (filter) {
      case _TimeFilter.day:
        final h = d.hour.toString().padLeft(2, '0');
        return '${h}h';
      case _TimeFilter.week:
        final day = d.day.toString().padLeft(2, '0');
        return '$day/$m';
      case _TimeFilter.month:
        final day = d.day.toString().padLeft(2, '0');
        return '$day/$m';
      case _TimeFilter.year:
        return 'T${d.month}';
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - DateTime.monday));
    return DateTime(start.year, start.month, start.day);
  }

  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  DateTimeRange _rangeForFilter(_TimeFilter filter, DateTime anchor) {
    final dayStart = _startOfDay(anchor);
    switch (filter) {
      case _TimeFilter.day:
        return DateTimeRange(start: dayStart, end: _endOfDay(anchor));
      case _TimeFilter.week:
        final start = _startOfWeek(anchor);
        final end = start.add(const Duration(days: 6));
        return DateTimeRange(start: start, end: _endOfDay(end));
      case _TimeFilter.month:
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = _lastDayOfMonth(anchor);
        return DateTimeRange(start: start, end: _endOfDay(end));
      case _TimeFilter.year:
        final start = DateTime(anchor.year, 1, 1);
        final end = DateTime(anchor.year, 12, 31);
        return DateTimeRange(start: start, end: _endOfDay(end));
    }
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _formatDateShort(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  String _formatRangeLabel(DateTimeRange range) {
    final start = _startOfDay(range.start);
    final end = _startOfDay(range.end);
    final today = _startOfDay(DateTime.now());
    final isSingleDay = start.isAtSameMomentAs(end);
    if (isSingleDay && start.isAtSameMomentAs(today)) {
      return 'Hôm nay';
    }
    if (isSingleDay) {
      return _formatDateShort(range.start);
    }
    return '${_formatDateShort(range.start)} - ${_formatDateShort(range.end)}';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initialRange = [
      _startOfDay(_selectedRange.start),
      _endOfDay(_selectedRange.end),
    ];
    final picked = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year, now.month, now.day),
        selectedDayHighlightColor: _revenueColor,
        cancelButton: const Text('Hủy'),
        okButton: const Text('Lưu'),
      ),
      dialogSize: const Size(325, 400),
      value: initialRange,
      borderRadius: BorderRadius.circular(15),
    );
    if (picked == null || picked.isEmpty) return;

    final start = picked[0];
    final end = picked.length > 1 && picked[1] != null ? picked[1] : picked[0];
    if (start == null || end == null) return;

    setState(() {
      _selectedRange = DateTimeRange(
        start: _startOfDay(start),
        end: _endOfDay(end),
      );
    });
  }

  void _onFilterChanged(_TimeFilter value) {
    if (value == _selectedFilter) return;
    final range = _rangeForFilter(value, DateTime.now());
    setState(() {
      _selectedFilter = value;
      _selectedRange = range;
    });
  }

  void _goPreviousRange() {
    final current = _startOfDay(_selectedRange.start);
    DateTime anchor;
    switch (_selectedFilter) {
      case _TimeFilter.day:
        anchor = current.subtract(const Duration(days: 1));
        break;
      case _TimeFilter.week:
        anchor = current.subtract(const Duration(days: 7));
        break;
      case _TimeFilter.month:
        anchor = DateTime(current.year, current.month - 1, 1);
        break;
      case _TimeFilter.year:
        anchor = DateTime(current.year - 1, 1, 1);
        break;
    }
    setState(() => _selectedRange = _rangeForFilter(_selectedFilter, anchor));
  }

  bool _canGoNextRange() {
    final today = _startOfDay(DateTime.now());
    final rangeEnd = _startOfDay(_selectedRange.end);
    return rangeEnd.isBefore(today);
  }

  void _goNextRange() {
    if (!_canGoNextRange()) return;
    final current = _startOfDay(_selectedRange.start);
    DateTime anchor;
    switch (_selectedFilter) {
      case _TimeFilter.day:
        anchor = current.add(const Duration(days: 1));
        break;
      case _TimeFilter.week:
        anchor = current.add(const Duration(days: 7));
        break;
      case _TimeFilter.month:
        anchor = DateTime(current.year, current.month + 1, 1);
        break;
      case _TimeFilter.year:
        anchor = DateTime(current.year + 1, 1, 1);
        break;
    }
    setState(() => _selectedRange = _rangeForFilter(_selectedFilter, anchor));
  }

  Widget _buildChart(BuildContext context, _TimeSeries series) {
    double maxValue = 0.0;
    for (final v in series.revenue) {
      if (v > maxValue) maxValue = v;
    }
    if (maxValue == 0) maxValue = 1;

    final spots = <FlSpot>[];
    for (int i = 0; i < series.revenue.length; i++) {
      spots.add(FlSpot(i.toDouble(), series.revenue[i]));
    }
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
      spots.add(const FlSpot(1, 0));
    } else if (spots.length == 1) {
      spots.add(FlSpot(spots.first.x + 1, spots.first.y));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _chartPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D335A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: _revenueColor, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Xu hướng Doanh thu',
                  style: TextStyle(
                    color: _titleText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Lùi về trước',
                onPressed: _goPreviousRange,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Tiến về sau',
                onPressed: _canGoNextRange() ? _goNextRange : null,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxValue * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxValue / 5,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: _gridColor, strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: _gridColor, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: _gridColor),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Thời Gian',
                        style: TextStyle(color: _axisText, fontSize: 11),
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= series.labels.length) {
                          return const SizedBox.shrink();
                        }
                        final skip = series.labels.length > 14 ? 2 : 1;
                        if (idx % skip != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _formatSlotLabel(series.labels[idx], series.filter),
                            style: const TextStyle(
                              fontSize: 10,
                              color: _axisText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Giá trị (VNĐ)',
                      style: TextStyle(color: _axisText, fontSize: 11),
                    ),
                    axisNameSize: 28,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        final label = value >= 1000000000
                            ? '${(value / 1000000000).toStringAsFixed(1)}T'
                            : value >= 1000000
                            ? '${(value / 1000000).toStringAsFixed(1)}M'
                            : value >= 1000
                            ? '${(value / 1000).toStringAsFixed(1)}K'
                            : value >= 1
                            ? value.toStringAsFixed(0)
                            : value.toStringAsFixed(2);
                        return Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _axisText,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: _revenueColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartView(BuildContext context) {
    final emptySeries = _buildEmptySeries(_selectedFilter, _selectedRange);
    return Container(
      color: _chartBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildChart(context, emptySeries),
          const SizedBox(height: 8),
          _LegendRow(revenueColor: _revenueColor),
        ],
      ),
    );
  }

  Color _getColor(int index) {
    final colors = [
      const Color(0xFF4E86E6),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFFAF52DE),
      const Color(0xFF5856D6),
      const Color(0xFFFF2D55),
    ];
    return colors[index % colors.length];
  }

  Widget _buildPaymentPieChart(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final double total = entries.fold(0.0, (sum, e) => sum + e.value);
    if (total <= 0) return const SizedBox.shrink();

    int colorIndex = 0;
    final sections = entries.map((e) {
      final color = _getColor(colorIndex++);
      final percentage = (e.value / total) * 100;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sections,
        ),
      ),
    );
  }

  List<String> _selectedProductCategories = ['Tất cả'];

  String _inferCategoryFromStore(String? storeName) {
    if (storeName == null || storeName.isEmpty) return 'Khác';
    final s = storeName.toLowerCase();
    if (s.contains('tàu hỏa') || s.contains('tàu hoả')) return 'Vé tàu hoả';
    if (s.contains('tàu thủy') || s.contains('tàu thuỷ')) return 'Vé tàu thuỷ';
    if (s.contains('xe khách') || s.contains('nhà xe')) return 'Vé xe khách';
    if (s.contains('máy bay')) return 'Vé máy bay';
    if (s.contains('thuê ô tô') ||
        s.contains('thuê oto') ||
        s.contains('oto') ||
        s.contains('ô tô'))
      return 'Thuê Ô tô';
    if (s.contains('thuê xe máy') || s.contains('xe máy')) return 'Thuê Xe máy';
    if (s.contains('thuê xe đạp') || s.contains('xe đạp')) return 'Thuê Xe đạp';
    if (s.contains('thuê')) return 'Thuê phương tiện';
    if (s.contains('khách sạn') || s.contains('phòng') || s.contains('resort'))
      return 'Khách sạn';
    if (s.contains('ẩm thực') || s.contains('đồ ăn') || s.contains('nước uống'))
      return 'Ẩm thực';
    if (storeName.length > 20) return '${storeName.substring(0, 20)}...';
    return storeName;
  }

  List<_SoldItem> _getSoldItems(
    List<Map<String, dynamic>> orders,
    DateTimeRange range,
  ) {
    final rangeStart = _startOfDay(range.start);
    final rangeEnd = _endOfDay(range.end);

    final Map<String, _SoldItem> itemMap = {};

    for (final order in orders) {
      final status = order['status'] as String? ?? '';
      final s = status.toLowerCase();
      if (s == 'cancelled' ||
          s == 'đã huỷ' ||
          s == 'huỷ' ||
          s == 'hủy' ||
          s == 'đã hủy')
        continue;

      final date =
          (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (date.isBefore(rangeStart) || date.isAfter(rangeEnd)) continue;

      final items = order['items'] as List<dynamic>? ?? [];
      for (final i in items) {
        if (i is Map) {
          final name = (i['name'] as String?) ?? 'Sản phẩm không tên';
          final image = (i['image'] as String?) ?? '';
          final price = (i['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = (i['quantity'] as num?)?.toInt() ?? 1;
          final category =
              (i['category'] as String?) ??
              _inferCategoryFromStore(order['storeName'] as String?);

          final key = name;
          if (itemMap.containsKey(key)) {
            itemMap[key]!.quantity += quantity;
          } else {
            itemMap[key] = _SoldItem(
              name: name,
              image: image,
              price: price,
              quantity: quantity,
              category: category,
            );
          }
        }
      }
    }

    final list = itemMap.values.toList();
    list.sort(
      (a, b) => b.quantity.compareTo(a.quantity),
    ); // Sort by quantity sold descending
    return list;
  }

  void _showCategoryBottomSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Lọc theo danh mục',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: categories.map((cat) {
                        final isSelected = _selectedProductCategories.contains(
                          cat,
                        );
                        return FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setModalState(() {
                              if (cat == 'Tất cả') {
                                if (selected) {
                                  _selectedProductCategories = ['Tất cả'];
                                }
                              } else {
                                if (selected) {
                                  _selectedProductCategories.remove('Tất cả');
                                  _selectedProductCategories.add(cat);
                                } else {
                                  _selectedProductCategories.remove(cat);
                                  if (_selectedProductCategories.isEmpty) {
                                    _selectedProductCategories = ['Tất cả'];
                                  }
                                }
                              }
                            });
                            setState(() {});
                          },
                          selectedColor: _revenueColor.withValues(alpha: 0.12),
                          checkmarkColor: _revenueColor,
                          labelStyle: TextStyle(
                            color: isSelected ? _revenueColor : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? _revenueColor
                                : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _chartBg,
      appBar: AppBar(
        title: const Text('Doanh thu'),
        backgroundColor: _chartBg,
        foregroundColor: _titleText,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterBar(
                  selected: _selectedFilter,
                  onChanged: _onFilterChanged,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(_formatRangeLabel(_selectedRange)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseMenuService().streamBusinessOrders(),
        initialData: const <Map<String, dynamic>>[],
        builder: (context, snapshot) {
          final bookings = snapshot.data ?? const <Map<String, dynamic>>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              bookings.isEmpty) {
            return _buildEmptyChartView(context);
          }
          if (snapshot.hasError && bookings.isEmpty) {
            return _buildEmptyChartView(context);
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Không tải được dữ liệu doanh thu'),
            );
          }
          if (bookings.isEmpty) {
            return _buildEmptyChartView(context);
          }

          final notCancelled = bookings.where((b) {
            final status = b['status'] as String? ?? '';
            final s = status.toLowerCase();
            return s != 'cancelled' &&
                s != 'đã huỷ' &&
                s != 'huỷ' &&
                s != 'hủy' &&
                s != 'đã hủy';
          });
          if (notCancelled.isEmpty) {
            return _buildEmptyChartView(context);
          }

          final channels = _paymentChannels(bookings, _selectedRange);
          final channelEntries = channels.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final series = _buildSeries(
            bookings,
            _selectedFilter,
            _selectedRange,
          );

          // Lấy danh sách sản phẩm đã bán trong kỳ
          final soldItems = _getSoldItems(bookings, _selectedRange);
          final predefinedCats = [
            'Tất cả',
            'Vé tàu hoả',
            'Vé tàu thuỷ',
            'Vé xe khách',
            'Vé máy bay',
            'Thuê Ô tô',
            'Thuê Xe máy',
            'Thuê Xe đạp',
            'Thuê phương tiện',
            'Khách sạn',
            'Ẩm thực',
          ];

          final dynamicCats =
              soldItems
                  .map((e) => e.category)
                  .where((c) => !predefinedCats.contains(c) && c != 'Khác')
                  .toSet()
                  .toList()
                ..sort();

          final categories = [...predefinedCats, ...dynamicCats, 'Khác'];
          if (!_selectedProductCategories.any(
            (cat) => categories.contains(cat),
          )) {
            _selectedProductCategories = [
              'Tất cả',
            ]; // Reset if category not found in current range
          }
          final filteredItems = _selectedProductCategories.contains('Tất cả')
              ? soldItems
              : soldItems
                    .where(
                      (e) => _selectedProductCategories.contains(e.category),
                    )
                    .toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildChart(context, series),
              const SizedBox(height: 8),
              _LegendRow(revenueColor: _revenueColor),
              const SizedBox(height: 24),
              Text(
                'Kênh thanh toán',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: _titleText),
              ),
              const SizedBox(height: 8),
              if (channelEntries.isEmpty)
                const Text(
                  'Chưa có giao dịch hoàn tất.',
                  style: TextStyle(color: _axisText),
                ),
              _buildPaymentPieChart(channelEntries),
              ...channelEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final c = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColor(index),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(c.key, style: const TextStyle(color: _titleText)),
                  trailing: Text(
                    _formatCurrency(c.value),
                    style: const TextStyle(
                      color: _titleText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatRangeLabel(_selectedRange).toLowerCase() == 'hôm nay'
                        ? 'Sản phẩm đã bán hôm nay'
                        : 'Sản phẩm đã bán trong kỳ',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: _titleText),
                  ),
                  if (categories.isNotEmpty)
                    InkWell(
                      onTap: () => _showCategoryBottomSheet(categories),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                _selectedProductCategories.contains('Tất cả')
                                    ? 'Tất cả'
                                    : _selectedProductCategories.length == 1
                                    ? _selectedProductCategories.first
                                    : '${_selectedProductCategories.first} (+${_selectedProductCategories.length - 1})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.filter_alt_outlined,
                              size: 16,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Không có sản phẩm nào.',
                    style: TextStyle(color: _axisText),
                  ),
                ),
              ...filteredItems.map((item) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: item.image.isNotEmpty
                          ? SmartImage(
                              imageUrl: item.image,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      color: _titleText,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Đã bán: ${item.quantity}',
                    style: const TextStyle(color: _axisText),
                  ),
                  trailing: Text(
                    _formatCurrency(item.price * item.quantity),
                    style: const TextStyle(
                      color: _titleText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.revenueColor});

  final Color revenueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(
          color: revenueColor,
          label: 'Doanh thu (VNĐ)',
          textColor: _DoanhThuPageState._titleText,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.textColor,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: textColor)),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _TimeFilter selected;
  final ValueChanged<_TimeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget buildChip(String label, _TimeFilter value) {
      final active = value == selected;
      return ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onChanged(value),
        selectedColor: _DoanhThuPageState._revenueColor.withOpacity(0.12),
        labelStyle: TextStyle(
          color: active
              ? _DoanhThuPageState._revenueColor
              : _DoanhThuPageState._axisText,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
        side: BorderSide(
          color: active
              ? _DoanhThuPageState._revenueColor
              : _DoanhThuPageState._gridColor,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildChip('Ngày', _TimeFilter.day),
        buildChip('Tuần', _TimeFilter.week),
        buildChip('Tháng', _TimeFilter.month),
        buildChip('Năm', _TimeFilter.year),
      ],
    );
  }
}

class _TimeSeries {
  const _TimeSeries(this.labels, this.revenue, this.filter);

  final List<DateTime> labels;
  final List<double> revenue;
  final _TimeFilter filter;
}

enum _TimeFilter { day, week, month, year }

class _SoldItem {
  final String name;
  final String image;
  final double price;
  int quantity;
  final String category;

  _SoldItem({
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.category,
  });
}
