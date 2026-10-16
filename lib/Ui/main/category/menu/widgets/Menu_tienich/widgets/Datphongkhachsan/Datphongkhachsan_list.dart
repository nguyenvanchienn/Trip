import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';

import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Datphongkhachsan_detail.dart';
import 'Datphongkhachsan_booking.dart';

class HotelListPage extends StatefulWidget {
  const HotelListPage({super.key});

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  String _sort = 'none';
  double _minRating = 0.0;

  // Search and region filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  void _applySort(List<Map<String, dynamic>> hotels) {
    if (_sort == 'price_asc') {
      hotels.sort(
        (a, b) =>
            ((a['price'] ?? 0) as int).compareTo((b['price'] ?? 0) as int),
      );
    } else if (_sort == 'price_desc') {
      hotels.sort(
        (a, b) =>
            ((b['price'] ?? 0) as int).compareTo((a['price'] ?? 0) as int),
      );
    } else if (_sort == 'rating') {
      hotels.sort(
        (a, b) => ((b['rating'] ?? 0.0) as double).compareTo(
          (a['rating'] ?? 0.0) as double,
        ),
      );
    }
  }

  String _fmt(int v) {
    final s = v.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} ₫';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showFilterDialog() async {
    double min = _minRating;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Lọc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Xếp hạng tối thiểu:'),
                const SizedBox(width: 8),
                Text(min.toString()),
              ],
            ),
            Slider(
              value: min,
              onChanged: (v) => setState(() => min = v),
              min: 0,
              max: 5,
              divisions: 10,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _minRating = min);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseBusinessService().streamServices(
        collectionName: 'business_hotel_services',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Đặt phòng khách sạn')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final rawItems = snapshot.data ?? [];
        final List<Map<String, dynamic>>
        allHotels = rawItems.where((it) => it['status'] == 'active').map((it) {
          final extra = it['extra'] as Map<String, dynamic>? ?? {};
          final imageUrl =
              extra['imageUrl'] as String? ??
              'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800';
          double starClass = 0.0;
          if (extra['starRating'] != null) {
            final String rawStar = extra['starRating'].toString();
            final numStr = rawStar.replaceAll(RegExp(r'[^0-9.]'), '');
            starClass = double.tryParse(numStr) ?? 0.0;
          }
          double userRating = (it['rating'] as num?)?.toDouble() ?? 0.0;
          int reviewCount =
              (it['reviewCount'] as num?)?.toInt() ??
              (it['reviewsCount'] as num?)?.toInt() ??
              0;

          return {
            ...it,
            'id': it['id'],
            'ownerId': it['ownerId'],
            'name': it['name'] ?? '',
            'location': it['address'] ?? '',
            'starClass': starClass,
            'rating': userRating,
            'reviewCount': reviewCount,
            'price': (it['price'] as num?)?.toInt() ?? 0,
            'desc': it['description'] ?? '',
            'images': extra['images'] is List
                ? (extra['images'] as List).map((e) => e.toString()).toList()
                : [imageUrl],
            'amenities': extra['amenities'] is List
                ? (extra['amenities'] as List).map((e) => e.toString()).toList()
                : ['WiFi'],
          };
        }).toList();

        _applySort(allHotels);

        final query = _searchQuery.toLowerCase();
        final filtered = allHotels.where((h) {
          final meetsRating = (h['rating'] as double) >= _minRating;
          final name = (h['name'] as String).toLowerCase();
          final matchesQuery = query.isEmpty || name.contains(query);
          return meetsRating && matchesQuery;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Đặt phòng khách sạn'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const DonHangCuaBanPage(serviceType: 'hotel'),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'filter') {
                    _showFilterDialog();
                    return;
                  }
                  if (v.startsWith('sort')) {
                    setState(() {
                      _sort = v.substring(5);
                    });
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'filter', child: Text('Lọc')),
                  PopupMenuItem(
                    value: 'sort:price_asc',
                    child: Text('Giá: thấp → cao'),
                  ),
                  PopupMenuItem(
                    value: 'sort:price_desc',
                    child: Text('Giá: cao → thấp'),
                  ),
                  PopupMenuItem(value: 'sort:rating', child: Text('Xếp hạng')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _HotelSearchPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tìm kiếm khách sạn',
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
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Không tìm thấy khách sạn phù hợp'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final h = filtered[i];
                          final isOwner =
                              FirebaseAuth.instance.currentUser?.uid ==
                              (h['ownerId'] ?? '').toString();

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => HotelDetailPage(hotel: h),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 92,
                                        height: 72,
                                        child:
                                            (h['images'] != null &&
                                                (h['images'] as List)
                                                    .isNotEmpty)
                                            ? SmartImage(
                                                imageUrl: h['images'][0],
                                                fit: BoxFit.cover,
                                                placeholder: Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.hotel,
                                                    size: 36,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.hotel,
                                                  size: 36,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            h['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (h['starClass'] != null &&
                                              h['starClass'] > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Khách sạn ${(h['starClass'] as double) == (h['starClass'] as double).toInt() ? (h['starClass'] as double).toInt() : h['starClass']} sao',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            h['location'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Colors.orange[400],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${h['rating']} (${h['reviewCount']} đánh giá)',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _fmt(h['price'] as int),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (!isOwner)
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        HotelBookingPage(
                                                          hotel: h,
                                                        ),
                                                  ),
                                                ),
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
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HotelSearchPage extends StatefulWidget {
  const _HotelSearchPage();

  @override
  State<_HotelSearchPage> createState() => _HotelSearchPageState();
}

class _HotelSearchPageState extends State<_HotelSearchPage> {
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

  void _loadItems() {
    FirebaseBusinessService().streamServices(collectionName: 'business_hotel_services').listen((items) {
      if (!mounted) return;
      final hotels = items.where((it) => it['status'] == 'active').map((it) {
        final extra = it['extra'] as Map<String, dynamic>? ?? {};
        final imageUrl =
            extra['imageUrl'] as String? ??
            'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800';
        double starClass = 0.0;
        if (extra['starRating'] != null) {
          final String rawStar = extra['starRating'].toString();
          final numStr = rawStar.replaceAll(RegExp(r'[^0-9.]'), '');
          starClass = double.tryParse(numStr) ?? 0.0;
        }
        double userRating = (it['rating'] as num?)?.toDouble() ?? 0.0;
        int reviewCount =
            (it['reviewCount'] as num?)?.toInt() ??
            (it['reviewsCount'] as num?)?.toInt() ??
            0;

        return {
          ...it,
          'id': it['id'],
          'ownerId': it['ownerId'],
          'name': it['name'] ?? '',
          'location': it['address'] ?? '',
          'starClass': starClass,
          'rating': userRating,
          'reviewCount': reviewCount,
          'price': (it['price'] as num?)?.toInt() ?? 0,
          'desc': it['description'] ?? '',
          'images': extra['images'] is List
              ? (extra['images'] as List).map((e) => e.toString()).toList()
              : [imageUrl],
          'amenities': extra['amenities'] is List
              ? (extra['amenities'] as List).map((e) => e.toString()).toList()
              : ['WiFi'],
        };
      }).toList();
      setState(() {
        _allItems = hotels;
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
        _history = prefs.getStringList('hotel_search_history') ?? [];
      });
    }
  }

  Future<void> _saveHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setStringList('hotel_search_history', _history);
    if (mounted) setState(() {});
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hotel_search_history');
    if (mounted) setState(() => _history.clear());
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allItems.where((h) {
        final matchQ = q.isEmpty ||
            h['name'].toString().toLowerCase().contains(q) ||
            h['location'].toString().toLowerCase().contains(q);
        return matchQ;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fmt(int v) {
    final s = v.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
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
            hintText: 'Tìm kiếm khách sạn',
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
          if (!_hasSubmitted && _searchController.text.isEmpty && _history.isNotEmpty)
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
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy khách sạn nào',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final h = _filtered[index];
                  final isOwner = h['ownerId'] == currentUser?.uid;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HotelDetailPage(hotel: h),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 92,
                                height: 72,
                                child: (h['images'] != null && (h['images'] as List).isNotEmpty)
                                    ? SmartImage(
                                        imageUrl: h['images'][0],
                                        fit: BoxFit.cover,
                                        placeholder: Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.hotel,
                                            size: 36,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.hotel,
                                          size: 36,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (h['starClass'] != null && h['starClass'] > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Khách sạn ${(h['starClass'] as double) == (h['starClass'] as double).toInt() ? (h['starClass'] as double).toInt() : h['starClass']} sao',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    h['location'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.orange[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${h['rating']} (${h['reviewCount']} đánh giá)',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
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
                                  _fmt((h['price'] as num?)?.toInt() ?? 0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (!isOwner)
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => HotelBookingPage(
                                          hotel: h,
                                        ),
                                      ),
                                    ),
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
              ),
            ),
        ],
      ),
    );
  }
}
