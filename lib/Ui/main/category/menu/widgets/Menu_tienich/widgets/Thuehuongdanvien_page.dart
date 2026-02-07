import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Trạng thái dùng tiếng Việt (chỉ 2 trạng thái theo yêu cầu)
const String STATUS_UPCOMING = 'Sắp diễn ra';
const String STATUS_COMPLETED = 'Đã hoàn thành';

class ThuehuongdanvienPage extends StatefulWidget {
  const ThuehuongdanvienPage({super.key});

  @override
  State<ThuehuongdanvienPage> createState() => _ThuehuongdanvienPageState();
}

class _ThuehuongdanvienPageState extends State<ThuehuongdanvienPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _guides = [
    {
      'id': 1,
      'name': 'Nguyễn Văn A',
      'avatar': 'asset/images/employee-5.png',
      'languages': ['Tiếng Việt', 'Tiếng Anh'],
      'rating': 4.8,
      'reviews': 120,
      'pricePerDay': 800.0,
      'experience': '10 năm hướng dẫn Tour miền Bắc, leo núi, trekking.',
      'itineraryTips': 'Thích hợp cho khách yêu thiên nhiên và nhiếp ảnh',
      'available': true,
      'reviewsList': [
        {
          'author': 'Mai Lan',
          'rating': 5,
          'text': 'Anh rất nhiệt tình và hỗ trợ chụp ảnh đẹp.',
          'date': '2024-12-10',
        },
        {
          'author': 'Phong',
          'rating': 4,
          'text': 'Lịch trình phù hợp, tuy hơi mệt nhưng rất đáng.',
          'date': '2024-11-02',
        },
      ],
    },
    {
      'id': 2,
      'name': 'Trần Thị B',
      'avatar': 'asset/images/OIP.jpg',
      'languages': ['Tiếng Việt', 'Tiếng Anh', 'Tiếng Nhật'],
      'rating': 4.6,
      'reviews': 89,
      'pricePerDay': 950.0,
      'experience': 'Hướng dẫn viên địa phương, am hiểu văn hóa và ẩm thực.',
      'itineraryTips': 'Phù hợp cho tour ẩm thực và văn hoá',
      'available': true,
      'reviewsList': [
        {
          'author': 'Hải',
          'rating': 5,
          'text': 'Rất am hiểu ẩm thực địa phương, recommend!',
          'date': '2024-10-02',
        },
        {
          'author': 'Loan',
          'rating': 4,
          'text': 'Thái độ thân thiện, có nhiều kiến thức lịch sử.',
          'date': '2024-09-15',
        },
      ],
    },
    {
      'id': 3,
      'name': 'Lê C',
      'avatar': 'asset/images/anh-mo-ta.jpg',
      'languages': ['Tiếng Việt'],
      'rating': 4.4,
      'reviews': 42,
      'pricePerDay': 600.0,
      'experience': 'Giá cả cạnh tranh, kinh nghiệm tổ chức team nhỏ.',
      'itineraryTips': 'Tốt cho các nhóm budget',
      'available': false,
      'reviewsList': [
        {
          'author': 'Quân',
          'rating': 4,
          'text': 'Giá tốt, phù hợp nhóm nhỏ.',
          'date': '2024-08-20',
        },
      ],
    },
  ];

  String? _filterLanguage;
  double? _maxPrice;
  String _sort = 'Phù hợp';
  final Set<int> _favorites = {};

  // Booking history for the current user (kept in SharedPreferences). Each booking: {id, guideId, guideName, start, days, status, completedAt?, review?}
  // Số ngày (khoảng thời gian) sau khi hoàn thành mà người dùng được phép viết/sửa đánh giá.
  // CHÚ Ý: Đây là "chỗ đợi 7 ngày" mà bạn hỏi — nếu muốn thay đổi thời gian cho phép, chỉnh giá trị này.
  final int _reviewWindowDays = 7;

  final List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('guide_bookings');
      if (s == null || s.isEmpty) return;
      final List<dynamic> data = json.decode(s);
      _bookings.clear();
      _bookings.addAll(data.map((e) => Map<String, dynamic>.from(e as Map)));
      // Normalize any legacy English status values to our Vietnamese constants
      for (var b in _bookings) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        if (s == 'upcoming') b['status'] = STATUS_UPCOMING;
        if (s == 'completed') b['status'] = STATUS_COMPLETED;
      }
      // refresh status if any booking passed its end date
      _refreshBookingsStatus();
      setState(() {});
    } catch (_) {}
  }

  // Parse dd/mm/yyyy to DateTime, return null if invalid
  DateTime? _parseDate(String s) {
    try {
      final parts = s.split('/');
      if (parts.length < 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Automatically check bookings and mark as completed when booking end date has passed
  void _refreshBookingsStatus() {
    bool changed = false;
    final now = DateTime.now();
    for (var b in _bookings) {
      if (b['status'] == STATUS_UPCOMING) {
        final start = _parseDate(b['start'] as String? ?? '');
        final days = (b['days'] as int?) ?? 1;
        if (start != null) {
          final end = start.add(Duration(days: days - 1));
          if (now.isAfter(end) || now.isAtSameMomentAs(end)) {
            b['status'] = STATUS_COMPLETED;
            b['completedAt'] = end.toIso8601String();
            changed = true;
          }
        }
      }
    }
    if (changed) {
      _saveBookings();
      setState(() {});
    }
  }

  Future<void> _saveBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guide_bookings', json.encode(_bookings));
    } catch (_) {}
  }

  // Thêm dữ liệu demo vào lịch sử để minh họa các trạng thái và tính năng
  void _insertDemoBookings() {
    final now = DateTime.now();
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

    final b1Start = now.add(const Duration(days: 5)); // future upcoming
    final b2Start = now.subtract(
      const Duration(days: 1),
    ); // ongoing (2/3 of 3-day)
    final b3Start = now.subtract(const Duration(days: 5)); // completed recently
    final b4Start = now.subtract(
      const Duration(days: 3),
    ); // completed with review
    final b5Start = now.subtract(
      const Duration(days: 15),
    ); // completed expired (>7 days)

    final demo = <Map<String, dynamic>>[
      {
        'id': DateTime.now().millisecondsSinceEpoch + 1,
        'guideId': 1,
        'guideName': 'Nguyễn Văn A',
        'start': fmt(b1Start),
        'days': 3,
        'status': STATUS_UPCOMING,
      },
      {
        'id': DateTime.now().millisecondsSinceEpoch + 2,
        'guideId': 1,
        'guideName': 'Nguyễn Văn A',
        'start': fmt(b2Start),
        'days': 3,
        'status': STATUS_UPCOMING, // started, elapsed >= 2/3
      },
      {
        'id': DateTime.now().millisecondsSinceEpoch + 3,
        'guideId': 2,
        'guideName': 'Trần Thị B',
        'start': fmt(b3Start),
        'days': 2,
        'status': STATUS_COMPLETED,
        'completedAt': b3Start
            .add(const Duration(days: 2 - 1))
            .toIso8601String(),
      },
      {
        'id': DateTime.now().millisecondsSinceEpoch + 4,
        'guideId': 1,
        'guideName': 'Nguyễn Văn A',
        'start': fmt(b4Start),
        'days': 1,
        'status': STATUS_COMPLETED,
        'completedAt': b4Start
            .add(const Duration(days: 1 - 1))
            .toIso8601String(),
        'review': {
          'author': 'Bạn',
          'rating': 5,
          'text': 'Rất tốt',
          'date': _formatDate(now.subtract(const Duration(days: 1))),
        },
      },
      {
        'id': DateTime.now().millisecondsSinceEpoch + 5,
        'guideId': 3,
        'guideName': 'Lê C',
        'start': fmt(b5Start),
        'days': 1,
        'status': STATUS_COMPLETED,
        'completedAt': b5Start
            .add(const Duration(days: 1 - 1))
            .toIso8601String(),
      },
    ];

    setState(() {
      _bookings.clear();
      _bookings.addAll(demo);
    });
    _saveBookings();
  }

  List<Map<String, dynamic>> get _filteredGuides {
    final q = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> list = _guides.where((g) {
      final matchQ =
          q.isEmpty ||
          g['name'].toString().toLowerCase().contains(q) ||
          (g['languages'] as List).any(
            (l) => l.toString().toLowerCase().contains(q),
          );
      final matchLang =
          _filterLanguage == null ||
          (g['languages'] as List).contains(_filterLanguage);
      final matchPrice =
          _maxPrice == null || (g['pricePerDay'] as double) <= _maxPrice!;
      return matchQ && matchLang && matchPrice;
    }).toList();

    if (_sort == 'Đánh giá') {
      list.sort(
        (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
      );
    } else if (_sort == 'Giá: Thấp') {
      list.sort(
        (a, b) =>
            (a['pricePerDay'] as double).compareTo(b['pricePerDay'] as double),
      );
    } else if (_sort == 'Giá: Cao') {
      list.sort(
        (a, b) =>
            (b['pricePerDay'] as double).compareTo(a['pricePerDay'] as double),
      );
    }

    return list;
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        String? lang = _filterLanguage;
        double? maxP = _maxPrice;
        String sort = _sort;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lọc & Sắp xếp',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ngôn ngữ'),
                  Wrap(
                    spacing: 8,
                    children: ['Tiếng Việt', 'English', '日本語'].map((l) {
                      final sel = lang == l;
                      return ChoiceChip(
                        label: Text(l),
                        selected: sel,
                        onSelected: (v) =>
                            setStateSheet(() => lang = v ? l : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Giá tối đa / ngày (k) '),
                  Slider(
                    value: maxP ?? 1000.0,
                    min: 200,
                    max: 2000,
                    divisions: 18,
                    label: '${(maxP ?? 1000).toInt()}k',
                    onChanged: (v) => setStateSheet(() => maxP = v),
                  ),
                  const SizedBox(height: 6),
                  const Text('Sắp xếp'),
                  Wrap(
                    spacing: 8,
                    children: ['Phù hợp', 'Đánh giá', 'Giá: Thấp', 'Giá: Cao']
                        .map((s) {
                          final sel = sort == s;
                          return ChoiceChip(
                            label: Text(s),
                            selected: sel,
                            onSelected: (v) =>
                                setStateSheet(() => sort = v ? s : sort),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterLanguage = lang;
                            _maxPrice = maxP;
                            _sort = sort;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Áp dụng'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBookingHistory() {
    // Refresh booking statuses before showing history, so auto-complete can run
    _refreshBookingsStatus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Constrain height and allow scrolling to avoid BOTTOM OVERFLOW
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: StatefulBuilder(
                builder: (context, setStateSheet) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch sử đặt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_bookings.isEmpty)
                          const Text('Chưa có đặt chỗ nào.'),
                        ..._bookings.map((b) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(b['guideName'].toString()),
                              subtitle: Text(
                                'Từ: ${b['start']} • ${b['days']} ngày • Trạng thái: ${b['status']}',
                              ),
                              trailing: Builder(
                                builder: (context) {
                                  final now = DateTime.now();
                                  // whether this booking already has a review
                                  final hasReview = b['review'] != null;

                                  if (b['status'] == STATUS_UPCOMING) {
                                    // For 'Sắp diễn ra': do not allow immediate review.
                                    // Allow 'Đánh giá' only after 2/3 of the booking duration has elapsed.
                                    final startDate = _parseDate(
                                      b['start'] as String? ?? '',
                                    );
                                    final days = (b['days'] as int?) ?? 1;
                                    if (startDate != null) {
                                      // Normalize days to avoid time-of-day issues
                                      final startDay = DateTime(
                                        startDate.year,
                                        startDate.month,
                                        startDate.day,
                                      );
                                      final nowDay = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      );

                                      // Nếu booking chưa bắt đầu thì không hiển thị nút gì
                                      if (nowDay.isBefore(startDay)) {
                                        return const SizedBox.shrink();
                                      }

                                      // Booking đã bắt đầu -> kiểm tra elapsed / threshold
                                      final elapsedDays =
                                          nowDay.difference(startDay).inDays +
                                          1; // inclusive count
                                      final threshold = ((2 * days) / 3).ceil();

                                      // Nếu đã trôi qua >= 2/3 và chưa có review -> cho 'Đánh giá'
                                      if (!hasReview &&
                                          elapsedDays >= threshold) {
                                        return TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Future.microtask(
                                              () =>
                                                  _openWriteReviewForBooking(b),
                                            );
                                          },
                                          child: const Text('Đánh giá'),
                                        );
                                      }

                                      // Ngược lại (đã bắt đầu nhưng chưa đủ 2/3) -> cho phép 'Đánh dấu hoàn thành' để khách tự xác nhận
                                      return TextButton(
                                        onPressed: () {
                                          setState(() {
                                            b['status'] = STATUS_COMPLETED;
                                            b['completedAt'] = DateTime.now()
                                                .toIso8601String();
                                          });
                                          _saveBookings();
                                          setStateSheet(() {});
                                          setState(() {});
                                          Navigator.pop(context);
                                          // open review immediately
                                          Future.microtask(
                                            () => _openWriteReviewForBooking(b),
                                          );
                                        },
                                        child: const Text(
                                          'Đánh dấu hoàn thành',
                                        ),
                                      );
                                    }

                                    // Nếu không có startDate hợp lệ, an toàn hiển thị nút 'Đánh dấu hoàn thành'
                                    return TextButton(
                                      onPressed: () {
                                        setState(() {
                                          b['status'] = STATUS_COMPLETED;
                                          b['completedAt'] = DateTime.now()
                                              .toIso8601String();
                                        });
                                        _saveBookings();
                                        setStateSheet(() {});
                                        setState(() {});
                                        Navigator.pop(context);
                                        // open review immediately
                                        Future.microtask(
                                          () => _openWriteReviewForBooking(b),
                                        );
                                      },
                                      child: const Text('Đánh dấu hoàn thành'),
                                    );
                                  }

                                  if (b['status'] == STATUS_COMPLETED) {
                                    // Chuẩn hóa so sánh theo ngày (date-only) để tránh lỗi time-of-day
                                    final completedAtRaw =
                                        b['completedAt'] ?? '';
                                    final completedAtParsed =
                                        DateTime.tryParse(completedAtRaw) ??
                                        DateTime.now().subtract(
                                          Duration(days: _reviewWindowDays + 1),
                                        );
                                    final completedDay = DateTime(
                                      completedAtParsed.year,
                                      completedAtParsed.month,
                                      completedAtParsed.day,
                                    );
                                    final nowDay = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    );
                                    final completedDiff = nowDay
                                        .difference(completedDay)
                                        .inDays;

                                    // Nếu đã qua >= _reviewWindowDays kể từ khi hoàn thành -> hiện 'Đặt lại'
                                    if (completedDiff >= _reviewWindowDays) {
                                      return TextButton(
                                        onPressed: () {
                                          final guide = _guides.firstWhere(
                                            (g) => g['id'] == b['guideId'],
                                            orElse: () => <String, dynamic>{},
                                          );
                                          Navigator.pop(context);
                                          Future.microtask(
                                            () => _openBookingSheet(guide),
                                          );
                                        },
                                        child: const Text('Đặt lại'),
                                      );
                                    }

                                    // Chưa quá hạn đặt lại: cho phép viết hoặc sửa đánh giá trong khung _reviewWindowDays
                                    if (!hasReview &&
                                        completedDiff < _reviewWindowDays) {
                                      return TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Future.microtask(
                                            () => _openWriteReviewForBooking(b),
                                          );
                                        },
                                        child: const Text('Đánh giá'),
                                      );
                                    }

                                    if (hasReview) {
                                      final reviewDate =
                                          DateTime.tryParse(
                                            b['review']['date'] ?? '',
                                          ) ??
                                          DateTime.now();
                                      final reviewDay = DateTime(
                                        reviewDate.year,
                                        reviewDate.month,
                                        reviewDate.day,
                                      );
                                      if (nowDay.difference(reviewDay).inDays <=
                                          _reviewWindowDays) {
                                        return TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Future.microtask(
                                              () => _openWriteReviewForBooking(
                                                b,
                                                edit: true,
                                              ),
                                            );
                                          },
                                          child: const Text('Sửa đánh giá'),
                                        );
                                      }
                                    }

                                    return const SizedBox.shrink();
                                  }

                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đóng'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _addOrEditReviewToGuide(
    int guideId,
    Map<String, dynamic> review, {
    String? oldDate,
  }) {
    final idx = _guides.indexWhere((g) => g['id'] == guideId);
    if (idx == -1) return;
    final g = _guides[idx];
    final reviews = List<Map<String, dynamic>>.from(
      g['reviewsList'] as List? ?? [],
    );
    int currentCount = (g['reviews'] as int?) ?? reviews.length;
    double currentRating = (g['rating'] as double?) ?? 0.0;

    if (oldDate != null) {
      final rIdx = reviews.indexWhere(
        (r) => r['date'] == oldDate && r['author'] == 'Bạn',
      );
      if (rIdx != -1) {
        final oldRating = (reviews[rIdx]['rating'] as num).toDouble();
        reviews[rIdx] = review;
        final newRating = currentCount == 0
            ? (review['rating'] as num).toDouble()
            : ((currentRating * currentCount) -
                      oldRating +
                      (review['rating'] as num)) /
                  currentCount;
        g['reviewsList'] = reviews;
        g['rating'] = newRating;
        setState(() {});
        return;
      }
    }
    // insert new
    reviews.insert(0, review);
    final newCount = currentCount + 1;
    final newRating =
        (currentRating * currentCount + (review['rating'] as num)) / newCount;
    g['reviewsList'] = reviews;
    g['reviews'] = newCount;
    g['rating'] = newRating;
    setState(() {});
  }

  void _openWriteReviewForBooking(
    Map<String, dynamic> booking, {
    bool edit = false,
  }) {
    final guideId = booking['guideId'] as int;
    final TextEditingController controller = TextEditingController(
      text: edit && booking['review'] != null
          ? booking['review']['text'] as String
          : '',
    );
    int selected = edit && booking['review'] != null
        ? (booking['review']['rating'] as int)
        : 5;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setStateSheet) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Viết đánh giá',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Chọn số sao'),
                        Row(
                          children: List.generate(5, (i) {
                            final idx = i + 1;
                            return IconButton(
                              onPressed: () =>
                                  setStateSheet(() => selected = idx),
                              icon: Icon(
                                idx <= selected
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Viết nhận xét của bạn...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                final text = controller.text.trim();
                                if (text.isEmpty) return;
                                final now = DateTime.now();
                                final review = {
                                  'author': 'Bạn',
                                  'rating': selected,
                                  'text': text,
                                  'date': _formatDate(now),
                                };
                                // add or edit review on guide
                                _addOrEditReviewToGuide(
                                  guideId,
                                  review,
                                  oldDate: edit && booking['review'] != null
                                      ? booking['review']['date'] as String
                                      : null,
                                );
                                // attach to booking and persist
                                booking['review'] = review;
                                _saveBookings();
                                // close and refresh
                                Navigator.pop(context);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cảm ơn bạn đã gửi đánh giá'),
                                  ),
                                );
                              },
                              child: const Text('Gửi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openBookingSheet(Map<String, dynamic> guide) async {
    DateTime? start = DateTime.now().add(const Duration(days: 1));
    int days = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đặt hướng dẫn viên: ${guide['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Ngày bắt đầu: '),
                        TextButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: start!,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (d != null) setStateSheet(() => start = d);
                          },
                          child: Text(
                            start != null
                                ? '${start!.day}/${start!.month}/${start!.year}'
                                : 'Chọn ngày',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Số ngày: '),
                        IconButton(
                          onPressed: () => setStateSheet(
                            () => days = days > 1 ? days - 1 : 1,
                          ),
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$days'),
                        IconButton(
                          onPressed: () => setStateSheet(() => days++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            final booking = {
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'guideId': guide['id'],
                              'guideName': guide['name'],
                              'start':
                                  '${start!.day}/${start!.month}/${start!.year}',
                              'days': days,
                              'status': STATUS_UPCOMING,
                            };
                            setState(() {
                              _bookings.add(booking);
                            });
                            _saveBookings();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đặt chỗ đã được thêm vào lịch sử: ${guide['name']}',
                                ),
                              ),
                            );
                          },
                          child: const Text('Xác nhận'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openGuideDetail(Map<String, dynamic> guide) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThuehuongdanvienDetailPage(
          guide: guide,
          bookings: _bookings,
          onBooked: (booking) {
            setState(() => _bookings.add(booking));
            _saveBookings();
          },
          onBookingsUpdated: () => _saveBookings(),
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuê hướng dẫn viên'),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _openBookingHistory,
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử đặt',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm tên hoặc ngôn ngữ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => _searchController.clear(),
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text('Kết quả: ${_filteredGuides.length}'),
                const Spacer(),
                DropdownButton<String>(
                  value: _sort,
                  items: ['Phù hợp', 'Đánh giá', 'Giá: Thấp', 'Giá: Cao']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _sort = v ?? 'Phù hợp'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final g = _filteredGuides[index];
                final fav = _favorites.contains(g['id'] as int);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () => _openGuideDetail(g),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage(g['avatar'] as String),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        g['name'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (fav)
                                            _favorites.remove(g['id'] as int);
                                          else
                                            _favorites.add(g['id'] as int);
                                        });
                                      },
                                      icon: Icon(
                                        fav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: fav ? Colors.red : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  g['experience'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text('${g['rating']}'),
                                    const SizedBox(width: 12),
                                    Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 6),
                                    Text('${g['reviews']} review'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(g['pricePerDay'] as double).toStringAsFixed(0)}k / ngày',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: g['available'] == true
                                    ? () => _openBookingSheet(g)
                                    : null,
                                child: const Text('Đặt'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _filteredGuides.length,
            ),
          ),
        ],
      ),
    );
  }
}

class ThuehuongdanvienDetailPage extends StatefulWidget {
  final Map<String, dynamic> guide;
  final List<Map<String, dynamic>> bookings;
  final void Function(Map<String, dynamic>)? onBooked;
  final VoidCallback? onBookingsUpdated;
  const ThuehuongdanvienDetailPage({
    super.key,
    required this.guide,
    this.bookings = const [],
    this.onBooked,
    this.onBookingsUpdated,
  });

  @override
  State<ThuehuongdanvienDetailPage> createState() =>
      _ThuehuongdanvienDetailPageState();
}

class _ThuehuongdanvienDetailPageState
    extends State<ThuehuongdanvienDetailPage> {
  late List<Map<String, dynamic>> _reviews;
  late double _rating;
  late int _reviewCount;

  @override
  void initState() {
    super.initState();
    _reviews = List<Map<String, dynamic>>.from(
      widget.guide['reviewsList'] as List? ?? [],
    );
    _rating = (widget.guide['rating'] as double?) ?? 0.0;
    _reviewCount = (widget.guide['reviews'] as int?) ?? _reviews.length;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _addReview(Map<String, dynamic> review, {String? oldDate}) {
    setState(() {
      final oldTotal = _rating * _reviewCount;
      if (oldDate != null) {
        final rIdx = _reviews.indexWhere(
          (r) => r['date'] == oldDate && r['author'] == 'Bạn',
        );
        if (rIdx != -1) {
          final oldRating = (_reviews[rIdx]['rating'] as num).toDouble();
          _reviews[rIdx] = review;
          _rating = _reviewCount == 0
              ? (review['rating'] as num).toDouble()
              : ((oldTotal - oldRating + (review['rating'] as num)) /
                    _reviewCount);
        } else {
          _reviews.insert(0, review);
          _reviewCount = _reviews.length;
          _rating = (_reviewCount == 0)
              ? (review['rating'] as num).toDouble()
              : (oldTotal + (review['rating'] as num)) / _reviewCount;
        }
      } else {
        _reviews.insert(0, review);
        _reviewCount = _reviews.length;
        _rating = (_reviewCount == 0)
            ? (review['rating'] as num).toDouble()
            : (oldTotal + (review['rating'] as num)) / _reviewCount;
      }
      // keep the source guide map in sync
      widget.guide['reviewsList'] = _reviews;
      widget.guide['reviews'] = _reviewCount;
      widget.guide['rating'] = _rating;
    });

    // attach review to matching booking (if exists)
    final bIdx = widget.bookings.indexWhere(
      (b) =>
          b['guideId'] == widget.guide['id'] && b['status'] == STATUS_COMPLETED,
    );
    if (bIdx != -1) {
      widget.bookings[bIdx]['review'] = review;
      widget.onBookingsUpdated?.call();
      setState(() {});
    }
  }

  void _openWriteReviewSheet() {
    final hasCompleted = (widget.bookings).any(
      (b) =>
          b['guideId'] == widget.guide['id'] && b['status'] == STATUS_COMPLETED,
    );
    if (!hasCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn chỉ có thể đánh giá khi chuyến đi hoàn thành và có trong lịch sử đặt',
          ),
        ),
      );
      return;
    }

    final TextEditingController controller = TextEditingController();
    int selected = 5;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setStateSheet) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Viết đánh giá',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Chọn số sao'),
                        Row(
                          children: List.generate(5, (i) {
                            final idx = i + 1;
                            return IconButton(
                              onPressed: () =>
                                  setStateSheet(() => selected = idx),
                              icon: Icon(
                                idx <= selected
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Viết nhận xét của bạn...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                final text = controller.text.trim();
                                if (text.isEmpty) return;
                                final now = DateTime.now();
                                final review = {
                                  'author': 'Bạn',
                                  'rating': selected,
                                  'text': text,
                                  'date': _formatDate(now),
                                };
                                final bIdx = widget.bookings.indexWhere(
                                  (b) =>
                                      b['guideId'] == widget.guide['id'] &&
                                      b['status'] == STATUS_COMPLETED,
                                );
                                final oldDate =
                                    bIdx != -1 &&
                                        widget.bookings[bIdx]['review'] != null
                                    ? widget.bookings[bIdx]['review']['date']
                                          as String
                                    : null;
                                _addReview(review, oldDate: oldDate);
                                if (bIdx != -1)
                                  widget.bookings[bIdx]['review'] = review;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cảm ơn bạn đã gửi đánh giá'),
                                  ),
                                );
                              },
                              child: const Text('Gửi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openBookingSheet() {
    DateTime start = DateTime.now().add(const Duration(days: 1));
    int days = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setStateSheet) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đặt hướng dẫn viên: ${widget.guide['name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Ngày bắt đầu: '),
                            TextButton(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: start,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (d != null) setStateSheet(() => start = d);
                              },
                              child: Text(
                                '${start.day}/${start.month}/${start.year}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Số ngày: '),
                            IconButton(
                              onPressed: () => setStateSheet(
                                () => days = days > 1 ? days - 1 : 1,
                              ),
                              icon: const Icon(Icons.remove),
                            ),
                            Text('$days'),
                            IconButton(
                              onPressed: () => setStateSheet(() => days++),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                final booking = {
                                  'id': DateTime.now().millisecondsSinceEpoch,
                                  'guideId': widget.guide['id'],
                                  'guideName': widget.guide['name'],
                                  'start':
                                      '${start.day}/${start.month}/${start.year}',
                                  'days': days,
                                  'status': STATUS_UPCOMING,
                                };
                                widget.onBooked?.call(booking);
                                // notify parent to persist bookings
                                widget.onBookingsUpdated?.call();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đặt chỗ đã được thêm vào lịch sử: ${widget.guide['name']}',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStars(double r) {
    final full = r.floor();
    final hasHalf = (r - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full)
          return const Icon(Icons.star, size: 16, color: Colors.amber);
        if (i == full && hasHalf)
          return const Icon(Icons.star_half, size: 16, color: Colors.amber);
        return const Icon(Icons.star_border, size: 16, color: Colors.amber);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    return Scaffold(
      appBar: AppBar(title: Text(guide['name'] as String)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: AssetImage(guide['avatar'] as String),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: (guide['languages'] as List)
                            .map<Widget>((l) => Chip(label: Text(l.toString())))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Đánh giá: ${_rating.toStringAsFixed(1)} • $_reviewCount review',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              'Kinh nghiệm',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(guide['experience'] as String),
            const SizedBox(height: 12),
            Text(
              'Gợi ý lịch trình',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(guide['itineraryTips'] as String? ?? '-'),
            const SizedBox(height: 12),
            Text('Giá', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${(guide['pricePerDay'] as double).toStringAsFixed(0)}k / ngày',
              style: const TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final bs = widget.bookings
                    .where((b) => b['guideId'] == guide['id'])
                    .toList();
                if (bs.isEmpty) return const SizedBox.shrink();
                final b = bs.last;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_note,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trạng thái đặt: ${b['status']}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Đánh giá',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _buildStars(_rating),
                    const SizedBox(width: 8),
                    Text(
                      '($_reviewCount)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _openWriteReviewSheet,
                  child: const Text('Viết đánh giá'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_reviews.isEmpty) ...[
              const Text('Chưa có đánh giá nào.'),
            ] else
              ..._reviews.map((r) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                (r['author'] as String).substring(0, 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        r['author'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _buildStars(
                                        (r['rating'] as num).toDouble(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(r['text'] as String),
                                  const SizedBox(height: 8),
                                  Text(
                                    r['date'] as String,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: widget.guide['available'] == true
              ? _openBookingSheet
              : null,
          label: Text(
            'Đặt ngay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: widget.guide['available'] == true
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 6,
        ),
      ),
    );
  }
}
