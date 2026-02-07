import 'package:flutter/material.dart';

import 'Datphongkhachsan_detail.dart';
import 'Datphongkhachsan_booking.dart';
import 'Datphongkhachsan_history.dart';

class HotelListPage extends StatefulWidget {
  const HotelListPage({super.key});

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  List<Map<String, dynamic>> hotels = [];
  String _sort = 'none';
  double _minRating = 0.0;

  // Search and region filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _regionFilter = <String>{};

  @override
  void initState() {
    super.initState();
    hotels = _sampleHotels();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  List<Map<String, dynamic>> _sampleHotels() {
    return [
      {
        'id': 'h1',
        'name': 'Hôtel Saigon Center',
        'location': 'Quận 1, TP. HCM',
        'rating': 4.6,
        'price': 1200000,
        'desc': 'Khách sạn 4 sao sang trọng gần trung tâm, tiện nghi đầy đủ.',
        'images': [
          'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800',
          'https://images.unsplash.com/photo-1501117716987-c8e2010b3f13?w=800',
        ],
        'amenities': ['WiFi', 'Bữa sáng', 'Hồ bơi'],
      },
      {
        'id': 'h2',
        'name': 'Hanoi Cozy Stay',
        'location': 'Hoàn Kiếm, Hà Nội',
        'rating': 4.4,
        'price': 800000,
        'desc': 'Khách sạn 3 sao ấm cúng, phù hợp cho chuyến công tác ngắn.',
        'images': [
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        ],
        'amenities': ['WiFi'],
      },
      {
        'id': 'h3',
        'name': 'Beachside Resort',
        'location': 'Nha Trang',
        'rating': 4.8,
        'price': 1500000,
        'desc': 'Resort ven biển với hồ bơi và bãi biển riêng.',
        'images': [
          'https://images.unsplash.com/photo-1501117716987-c8e2010b3f13?w=800',
        ],
        'amenities': ['WiFi', 'Hồ bơi', 'Spa'],
      },
    ];
  }

  void _applySort() {
    setState(() {
      if (_sort == 'price_asc') {
        hotels.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
      } else if (_sort == 'price_desc') {
        hotels.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
      } else if (_sort == 'rating') {
        hotels.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
        );
      }
    });
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

  Future<void> _showRegionSelector() async {
    // Open full-screen region selector (city / district picker)
    final result = await Navigator.of(context).push<Map<String, String>?>(
      MaterialPageRoute(
        builder: (_) =>
            RegionSelectorPage(hotels: hotels, initialSelection: _regionFilter),
        fullscreenDialog: true,
      ),
    );

    if (result == null) return;

    // reset
    if (result['city'] != null && result['city'] == '') {
      setState(() => _regionFilter.clear());
      return;
    }

    setState(() {
      _regionFilter.clear();
      if (result['district'] != null && result['district']!.isNotEmpty) {
        _regionFilter.add(result['district']!);
      } else if (result['city'] != null && result['city']!.isNotEmpty) {
        _regionFilter.add(result['city']!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery;
    final filtered = hotels.where((h) {
      final meetsRating = (h['rating'] as double) >= _minRating;
      final name = (h['name'] as String).toLowerCase();
      final matchesQuery = query.isEmpty || name.contains(query);
      final location = (h['location'] as String);
      final matchesRegion =
          _regionFilter.isEmpty ||
          _regionFilter.any((r) => location.contains(r));
      return meetsRating && matchesQuery && matchesRegion;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt phòng khách sạn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HotelBookingHistoryPage(),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'filter') {
                _showFilterDialog();
                return;
              }
              if (v == 'regions') {
                _showRegionSelector();
                return;
              }
              if (v.startsWith('sort')) {
                _sort = v.substring(5);
                _applySort();
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
              PopupMenuItem(value: 'regions', child: Text('Vị trí')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm khách sạn',
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final h = filtered[i];
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
                          Container(
                            width: 92,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.hotel,
                              size: 36,
                              color: Colors.grey,
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
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  h['location'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
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
                                    Text('${h['rating']}'),
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
                                _fmt(h['price'] as int),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HotelBookingPage(hotel: h),
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

// Full-screen region / district selector
class RegionSelectorPage extends StatefulWidget {
  const RegionSelectorPage({
    super.key,
    required this.hotels,
    required this.initialSelection,
  });

  final List<Map<String, dynamic>> hotels;
  final Set<String> initialSelection;

  @override
  State<RegionSelectorPage> createState() => _RegionSelectorPageState();
}

class _RegionSelectorPageState extends State<RegionSelectorPage> {
  final TextEditingController _search = TextEditingController();

  List<String> get _cities {
    final set = <String>{};
    for (final h in widget.hotels) {
      final loc = (h['location'] as String).trim();
      // assume format 'District, City' or just 'City'
      final parts = loc.split(',');
      final city = parts.length > 1 ? parts.last.trim() : loc;
      set.add(city);
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<String> _filterCities(String q) {
    if (q.isEmpty) return _cities;
    return _cities
        .where((c) => c.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final list = _filterCities(query);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: TextField(
          controller: _search,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm Quận/Huyện, Tỉnh/Thành',
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, {'city': '', 'district': ''}),
            child: const Text(
              'Thiết lập lại',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'Khu vực được chọn',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.initialSelection.isEmpty
                      ? 'Chưa chọn'
                      : widget.initialSelection.join(', '),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final city = list[index];
                final districts = _districtsFor(city);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(city),
                      trailing: districts.isEmpty
                          ? null
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        if (districts.isEmpty) {
                          Navigator.pop(context, {
                            'city': city,
                            'district': '',
                          });
                        } else {
                          final selected = await Navigator.of(context)
                              .push<String?>(
                                MaterialPageRoute(
                                  builder: (_) => DistrictSelectorPage(
                                    city: city,
                                    districts: districts,
                                  ),
                                ),
                              );
                          if (selected != null)
                            Navigator.pop(context, {
                              'city': city,
                              'district': selected,
                            });
                        }
                      },
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _districtsFor(String city) {
    final set = <String>{};
    for (final h in widget.hotels) {
      final loc = (h['location'] as String).trim();
      final parts = loc.split(',');
      if (parts.length > 1 && parts.last.trim() == city) {
        final district = parts.first.trim();
        set.add(district);
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }
}

class DistrictSelectorPage extends StatefulWidget {
  const DistrictSelectorPage({
    super.key,
    required this.city,
    required this.districts,
  });

  final String city;
  final List<String> districts;

  @override
  State<DistrictSelectorPage> createState() => _DistrictSelectorPageState();
}

class _DistrictSelectorPageState extends State<DistrictSelectorPage> {
  String? _sel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.districts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Không có dữ liệu huyện/quận'),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: widget.districts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = widget.districts[i];
                  return RadioListTile<String>(
                    value: d,
                    groupValue: _sel,
                    title: Text(d),
                    onChanged: (v) => setState(() => _sel = v),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sel == null
                        ? null
                        : () => Navigator.pop(context, _sel),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
