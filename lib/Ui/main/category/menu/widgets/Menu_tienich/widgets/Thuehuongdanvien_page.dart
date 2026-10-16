import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';

import 'package:tourn/Ui/main/category/business/business_profile_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Thuehuongdanvien_booking.dart';

// Trạng thái dùng tiếng Việt (chỉ 2 trạng thái theo yêu cầu)
const String STATUS_UPCOMING = 'Sắp diễn ra';
const String STATUS_COMPLETED = 'Đã hoàn thành';

class ThuehuongdanvienPage extends StatefulWidget {
  const ThuehuongdanvienPage({super.key});

  @override
  State<ThuehuongdanvienPage> createState() => _ThuehuongdanvienPageState();
}

class _ThuehuongdanvienPageState extends State<ThuehuongdanvienPage> {
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

  // Booking history for the current user (kept in SharedPreferences). Each booking: {id, guideId, guideName, start, days, status, completedAt?, review?}

  final List<Map<String, dynamic>> _bookings = [];
  late Stream<List<Map<String, dynamic>>> _guideStream;
  Future<DocumentSnapshot>? _ownerProfileFuture;

  @override
  void initState() {
    super.initState();
    _guideStream = FirebaseBusinessService().streamServices(
      collectionName: 'business_guide_services',
    );
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
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  String _fmtPrice(num val) {
    final str = (val * 1000).toStringAsFixed(0);
    return str.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
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

  void _openBookingSheet(Map<String, dynamic> guide) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuideBookingPage(
          guide: guide,
          onBooked: (booking) {
            setState(() {
              _bookings.add(booking);
            });
            _saveBookings();
          },
        ),
      ),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DonHangCuaBanPage(serviceType: 'guide_rental'),
                ),
              );
            },
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử đặt',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _guideStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawGuides = snapshot.data ?? [];
          List<Map<String, dynamic>> _filteredGuides = rawGuides
              .where((it) => it['status'] == 'active')
              .map((g) {
                final extra = g['extra'] as Map<String, dynamic>? ?? {};
                return {
                  'id': g['id'],
                  'ownerId': g['ownerId'],
                  'name': g['name'] ?? '',
                  'avatar': extra['imageUrl'] ?? 'asset/images/employee-5.png',
                  'images': extra['images'] is List
                      ? (extra['images'] as List)
                            .map((e) => e.toString())
                            .toList()
                      : [extra['imageUrl'] ?? 'asset/images/employee-5.png'],
                  'languages':
                      extra['languages']?.toString().split(',') ??
                      ['Tiếng Việt'],
                  'rating': (extra['rating'] as num?)?.toDouble() ?? 0.0,
                  'reviews': (extra['reviews'] as num?)?.toInt() ?? 0,
                  'pricePerDay': (g['price'] as num?)?.toDouble() ?? 0.0,
                  'experience': extra['experienceYears']?.toString() != null
                      ? '${extra['experienceYears']} năm kinh nghiệm'
                      : 'Hướng dẫn viên',
                  'itineraryTips': extra['specialty'] ?? '',
                  'available': true,
                  'reviewsList': extra['reviewsList'] is List
                      ? List<Map<String, dynamic>>.from(extra['reviewsList'])
                      : <Map<String, dynamic>>[],
                };
              })
              .toList();

          _filteredGuides = _filteredGuides.where((g) {
            final matchLang =
                _filterLanguage == null ||
                (g['languages'] as List).contains(_filterLanguage);
            final matchPrice =
                _maxPrice == null || (g['pricePerDay'] as double) <= _maxPrice!;
            return matchLang && matchPrice;
          }).toList();

          if (_sort == 'Đánh giá') {
            _filteredGuides.sort(
              (a, b) =>
                  (b['rating'] as double).compareTo(a['rating'] as double),
            );
          } else if (_sort == 'Giá: Thấp') {
            _filteredGuides.sort(
              (a, b) => (a['pricePerDay'] as double).compareTo(
                b['pricePerDay'] as double,
              ),
            );
          } else if (_sort == 'Giá: Cao') {
            _filteredGuides.sort(
              (a, b) => (b['pricePerDay'] as double).compareTo(
                a['pricePerDay'] as double,
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _TourGuideSearchPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tìm tên hoặc ngôn ngữ...',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text('Kết quả: ${_filteredGuides.length}'),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _sort,
                      items: ['Phù hợp', 'Đánh giá', 'Giá: Thấp', 'Giá: Cao']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _sort = v ?? 'Phù hợp'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredGuides.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final g = _filteredGuides[index];
                    final isOwner =
                        FirebaseAuth.instance.currentUser?.uid ==
                        (g['ownerId'] ?? '').toString();

                    Widget cardWidget = Card(
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
                                backgroundImage:
                                    (g['avatar'] as String).startsWith(
                                          'http',
                                        ) ||
                                        (g['avatar'] as String).startsWith(
                                          'data:image',
                                        )
                                    ? getImageProvider(g['avatar'] as String)
                                    : AssetImage(g['avatar'] as String)
                                          as ImageProvider,
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
                                  const SizedBox(height: 16),
                                  Text(
                                    '${_fmtPrice(g['pricePerDay'] as num)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (!isOwner)
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

                    final ownerId = (g['ownerId'] ?? '').toString();
                    if (ownerId.isNotEmpty) {
                      Widget currentCard = cardWidget;
                      cardWidget =
                          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance
                                .collection('user_profiles')
                                .doc(ownerId)
                                .get(),
                            builder: (context, profileSnap) {
                              final profileData =
                                  profileSnap.data?.data() ?? {};
                              final businessProfile =
                                  (profileData['businessProfile']
                                      as Map<String, dynamic>?) ??
                                  {};
                              final isOpen =
                                  businessProfile['isOpen'] as bool? ?? true;
                              return Opacity(
                                opacity: isOpen ? 1.0 : 0.5,
                                child: currentCard,
                              );
                            },
                          );
                    }

                    return cardWidget;
                  },
                ),
              ),
            ],
          );
        },
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

  bool _isBusy = false;
  bool _loadingBusy = true;

  @override
  void initState() {
    super.initState();
    _reviews = List<Map<String, dynamic>>.from(
      widget.guide['reviewsList'] as List? ?? [],
    );
    _rating = (widget.guide['rating'] as double?) ?? 0.0;
    _reviewCount = (widget.guide['reviews'] as int?) ?? _reviews.length;
    _checkAvailability();

    final ownerId = widget.guide['ownerId']?.toString() ?? '';
    if (ownerId.isNotEmpty) {
      _ownerProfileFuture = FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(ownerId)
          .get();
    }
  }

  Future<DocumentSnapshot>? _ownerProfileFuture;

  String _fmtPrice(num val) {
    final str = (val * 1000).toStringAsFixed(0);
    return str.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  Future<void> _checkAvailability() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tour_guide_orders')
          .where('guideId', isEqualTo: widget.guide['id'])
          .where('status', whereIn: ['pending', 'in_progress', 'upcoming'])
          .get();
      if (mounted) {
        setState(() {
          _isBusy = snap.docs.isNotEmpty;
          _loadingBusy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBusy = false);
      }
    }
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuideBookingPage(
          guide: widget.guide,
          onBooked: (booking) {
            widget.onBooked?.call(booking);
          },
        ),
      ),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.guide['name'] ?? '')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: ImageCarousel(
                images:
                    (widget.guide['images'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [widget.guide['avatar'] as String],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.guide['name'] as String,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              ' ($_reviewCount)',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_fmtPrice(widget.guide['pricePerDay'] as num)}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((widget.guide['ownerId'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    FutureBuilder<DocumentSnapshot>(
                      future: _ownerProfileFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox();

                        final businessProfile =
                            data['businessProfile'] as Map<String, dynamic>? ??
                            {};
                        final ownerProfile =
                            data['ownerProfile'] as Map<String, dynamic>? ?? {};

                        String _getValidString(
                          List<String?> values,
                          String defaultValue,
                        ) {
                          for (final v in values) {
                            if (v != null && v.trim().isNotEmpty)
                              return v.trim();
                          }
                          return defaultValue;
                        }

                        final storeName = _getValidString([
                          businessProfile['name'] as String?,
                          ownerProfile['name'] as String?,
                          data['fullName'] as String?,
                        ], 'Người đăng');

                        final media =
                            businessProfile['media'] as Map<String, dynamic>? ??
                            {};
                        final avatar = _getValidString([
                          media['avatarPath'] as String?,
                          media['avatar'] as String?,
                          data['avatar'] as String?,
                          data['photoURL'] as String?,
                          data['photoUrl'] as String?,
                        ], '');

                        final address = _getValidString([
                          businessProfile['address'] as String?,
                        ], 'Người đăng');

                        String displayAddress = address;
                        if (address != 'Người đăng') {
                          final parts = address
                              .split(',')
                              .map((e) => e.trim())
                              .toList();
                          if (parts.length >= 2) {
                            displayAddress =
                                '${parts[parts.length - 2]}, ${parts.last}';
                          }
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: avatar.isNotEmpty
                                ? getImageProvider(avatar)
                                : null,
                            child: avatar.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            storeName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            displayAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusinessProfilePage(
                                  ownerId: widget.guide['ownerId'].toString(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Ngôn ngữ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (widget.guide['languages'] as List).map((l) {
                      return Chip(
                        label: Text(l.toString()),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kinh nghiệm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.guide['experience'] as String,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Lịch trình phù hợp',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.guide['itineraryTips'] as String,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh giá',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openWriteReviewSheet,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Viết đánh giá'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    const Text('Chưa có đánh giá nào.')
                  else
                    ..._reviews.map((r) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          (FirebaseAuth.instance.currentUser?.uid !=
              (widget.guide['ownerId'] ?? '').toString())
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              height: 56,
              child: FloatingActionButton.extended(
                onPressed:
                    _loadingBusy || _isBusy || widget.guide['available'] != true
                    ? null
                    : _openBookingSheet,
                label: Text(
                  _loadingBusy
                      ? 'Đang kiểm tra...'
                      : (_isBusy ? 'Đang bận' : 'Đặt ngay'),
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
            )
          : null,
    );
  }
}

class _TourGuideSearchPage extends StatefulWidget {
  const _TourGuideSearchPage();

  @override
  State<_TourGuideSearchPage> createState() => _TourGuideSearchPageState();
}

class _TourGuideSearchPageState extends State<_TourGuideSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _history = [];
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  String _fmtPrice(num val) {
    final str = (val * 1000).toStringAsFixed(0);
    return str.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  void _loadItems() {
    FirebaseBusinessService()
        .streamServices(collectionName: 'business_guide_services')
        .listen((items) {
          if (!mounted) return;
          final guides = items.where((it) => it['status'] == 'active').map((
            it,
          ) {
            final extra = it['extra'] as Map<String, dynamic>? ?? {};
            return {
              'id': it['id'],
              'ownerId': it['ownerId'],
              'name': it['name'] ?? 'Hướng dẫn viên',
              'languages': extra['languages'] ?? ['Tiếng Việt'],
              'rating': (extra['rating'] as num?)?.toDouble() ?? 0.0,
              'pricePerDay': (it['price'] as num?)?.toDouble() ?? 0.0,
              'experience': extra['experienceYears']?.toString() != null
                  ? '${extra['experienceYears']} năm kinh nghiệm'
                  : 'Hướng dẫn viên',
              'avatar': extra['imageUrl'] ?? '',
              'itineraryTips': extra['specialty'] ?? '',
              'reviews': (extra['reviews'] as num?)?.toInt() ?? 0,
            };
          }).toList();
          setState(() {
            _allItems = guides;
            _applyFilters();
          });
        });
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty && _hasSubmitted) {
      _hasSubmitted = false;
    }
    _applyFilters();
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveHistory(query);
    setState(() {
      _hasSubmitted = true;
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _history = prefs.getStringList('guide_search_history') ?? [];
      });
    }
  }

  Future<void> _saveHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setStringList('guide_search_history', _history);
    if (mounted) setState(() {});
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guide_search_history');
    if (mounted) setState(() => _history.clear());
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allItems.where((it) {
        final matchQ =
            q.isEmpty ||
            it['name'].toString().toLowerCase().contains(q) ||
            (it['languages'] as List).any(
              (l) => l.toString().toLowerCase().contains(q),
            );
        return matchQ;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm tên hoặc ngôn ngữ...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _hasSubmitted = false);
                    },
                  )
                : null,
          ),
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey.shade200),
          if (!_hasSubmitted &&
              _searchController.text.isEmpty &&
              _history.isNotEmpty)
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tìm kiếm gần đây',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearHistory,
                          child: const Text('Xóa lịch sử'),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _history.map((h) {
                      return ActionChip(
                        label: Text(h),
                        onPressed: () {
                          _searchController.text = h;
                          _submitSearch(h);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
          else if (_filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy hướng dẫn viên nào',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final g = _filtered[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black12,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: g['avatar'].toString().isNotEmpty
                            ? NetworkImage(g['avatar'])
                            : null,
                        child: g['avatar'].toString().isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        g['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(g['experience']),
                          const SizedBox(height: 4),
                          Text(
                            (g['languages'] as List).join(' • '),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text('${g['rating']} (${g['reviews']})'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmtPrice(g['pricePerDay'] as num)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessProfilePage(
                              ownerId: g['ownerId'].toString(),
                            ),
                          ),
                        );
                      },
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
