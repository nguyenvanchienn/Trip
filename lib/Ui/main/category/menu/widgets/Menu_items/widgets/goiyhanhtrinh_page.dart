import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoiYHanhTrinhPage extends StatefulWidget {
  const GoiYHanhTrinhPage({super.key});

  @override
  State<GoiYHanhTrinhPage> createState() => _GoiYHanhTrinhPageState();
}

class _GoiYHanhTrinhPageState extends State<GoiYHanhTrinhPage> {
  final List<Map<String, dynamic>> _trips = [
    {
      'id': 't1',
      'title': 'Hà Nội - Ninh Bình: 2 ngày khám phá',
      'days': 2,
      'budget': 1500,
      'tags': ['Nature', 'History'],
      'rating': 4.7,
      'description':
          'Khám phá cố đô, tam cốc và những khung cảnh sông nước tuyệt đẹp.',
      'itinerary': ['Ngày 1: Hà Nội → Tràng An', 'Ngày 2: Hoa Lư, Bích Động'],
    },
    {
      'id': 't2',
      'title': 'Sài Gòn: 1 ngày ăn uống - checkin',
      'days': 1,
      'budget': 800,
      'tags': ['Food', 'City'],
      'rating': 4.3,
      'description':
          'Tour ẩm thực Sài Gòn: từ quán cóc đến nhà hàng nổi tiếng.',
      'itinerary': [
        'Sáng: Cà phê',
        'Trưa: Bánh mì/potential spots',
        'Chiều: Checkin quận 1',
      ],
    },
    {
      'id': 't3',
      'title': 'Đà Lạt lãng mạn 3 ngày',
      'days': 3,
      'budget': 2500,
      'tags': ['Nature', 'Couple'],
      'rating': 4.9,
      'description':
          'Thưởng thức không khí lạnh, đồi thông và quán cafe xinh xắn.',
      'itinerary': [
        'Ngày 1: Hồ Xuân Hương',
        'Ngày 2: Đỉnh Langbiang',
        'Ngày 3: Thung lũng Tình Yêu',
      ],
    },
  ];

  List<Map<String, dynamic>> _filtered = [];
  Set<String> _favorites = {};
  String _query = '';
  final List<String> _allTags = ['Nature', 'Food', 'City', 'History', 'Couple'];
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_trips);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('fav_trips') ?? [];
    setState(() => _favorites = list.toSet());
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fav_trips', _favorites.toList());
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    _saveFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favorites.contains(id) ? 'Đã lưu vào yêu thích' : 'Đã bỏ yêu thích',
        ),
      ),
    );
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    _filtered = _trips.where((t) {
      final title = (t['title'] as String).toLowerCase();
      final matchesQuery = q.isEmpty || title.contains(q);
      final tags = (t['tags'] as List).cast<String>();
      final matchesTags =
          _selectedTags.isEmpty || _selectedTags.any((s) => tags.contains(s));
      return matchesQuery && matchesTags;
    }).toList();
    setState(() {});
  }

  void _openDetail(Map<String, dynamic> trip) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            TripDetailPage(trip: trip, isFav: _favorites.contains(trip['id'])),
      ),
    );
    if (res == true) {
      // user toggled favorite in detail
      _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý hành trình')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm hành trình...',
              ),
              onChanged: (v) {
                _query = v;
                _applyFilter();
              },
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _allTags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (s) {
                        setState(() {
                          if (s) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                        _applyFilter();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text('Không tìm thấy hành trình phù hợp'),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final t = _filtered[i];
                        final id = t['id'] as String;
                        return Card(
                          child: InkWell(
                            onTap: () => _openDetail(t),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 88,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.landscape,
                                        size: 36,
                                        color: Colors.grey,
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
                                          t['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Chip(
                                              label: Text('${t['days']} ngày'),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                            ),
                                            Chip(
                                              label: Text('${t['budget']}k'),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: (t['tags'] as List)
                                              .map(
                                                (tag) => Chip(
                                                  label: Text(tag),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _favorites.contains(id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _toggleFavorite(id),
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
      ),
    );
  }
}

class TripDetailPage extends StatefulWidget {
  final Map<String, dynamic> trip;
  final bool isFav;
  const TripDetailPage({super.key, required this.trip, required this.isFav});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late bool _fav;

  @override
  void initState() {
    super.initState();
    _fav = widget.isFav;
  }

  Future<void> _toggleFav() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('fav_trips') ?? [];
    final favSet = list.toSet();
    final id = widget.trip['id'] as String;
    if (favSet.contains(id)) {
      favSet.remove(id);
    } else {
      favSet.add(id);
    }
    await prefs.setStringList('fav_trips', favSet.toList());
    setState(() => _fav = favSet.contains(id));
    // Return true so parent reloads
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    return Scaffold(
      appBar: AppBar(
        title: Text(t['title']),
        actions: [
          IconButton(
            icon: Icon(_fav ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFav,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bắt đầu hành trình (demo)')),
        ),
        label: const Text('Bắt đầu'),
        icon: const Icon(Icons.play_arrow),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.map, size: 64, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(t['description'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text(
              'Lịch trình',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...((t['itinerary'] as List)
                .map((s) => ListTile(title: Text(s)))
                .toList()),
          ],
        ),
      ),
    );
  }
}
