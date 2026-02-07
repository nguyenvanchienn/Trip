import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KhamPhaDiaDiemPage extends StatefulWidget {
  const KhamPhaDiaDiemPage({super.key});

  @override
  State<KhamPhaDiaDiemPage> createState() => _KhamPhaDiaDiemPageState();
}

class _KhamPhaDiaDiemPageState extends State<KhamPhaDiaDiemPage> {
  final List<Map<String, dynamic>> _places = [
    {
      'id': 'p1',
      'name': 'Hồ Gươm',
      'type': 'Sight',
      'rating': 4.6,
      'desc': 'Trung tâm Hà Nội',
    },
    {
      'id': 'p2',
      'name': 'Chợ Bến Thành',
      'type': 'Market',
      'rating': 4.1,
      'desc': 'Chợ nổi tiếng ở Sài Gòn',
    },
    {
      'id': 'p3',
      'name': 'Đồi Mộng Mơ',
      'type': 'Park',
      'rating': 4.3,
      'desc': 'Một địa điểm lãng mạn ở Đà Lạt',
    },
  ];

  List<Map<String, dynamic>> _filtered = [];
  Set<String> _favorites = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_places);
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = (prefs.getStringList('fav_places') ?? []).toSet();
    setState(() {});
  }

  Future<void> _toggleFav(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    await prefs.setStringList('fav_places', _favorites.toList());
    setState(() {});
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    _filtered = _places
        .where(
          (p) =>
              p['name'].toLowerCase().contains(q) ||
              p['type'].toLowerCase().contains(q),
        )
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khám phá địa điểm')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm địa điểm...',
              ),
              onChanged: (v) {
                _query = v;
                _applyFilter();
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('Không có địa điểm'))
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = _filtered[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.place),
                            title: Text(p['name']),
                            subtitle: Text('${p['type']} • ⭐ ${p['rating']}'),
                            trailing: IconButton(
                              icon: Icon(
                                _favorites.contains(p['id'])
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () => _toggleFav(p['id']),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlaceDetailPage(
                                  place: p,
                                  isFav: _favorites.contains(p['id']),
                                ),
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

class PlaceDetailPage extends StatefulWidget {
  final Map<String, dynamic> place;
  final bool isFav;
  const PlaceDetailPage({super.key, required this.place, required this.isFav});

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  late bool _fav;

  @override
  void initState() {
    super.initState();
    _fav = widget.isFav;
  }

  Future<void> _toggleFav() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('fav_places') ?? [];
    final set = list.toSet();
    final id = widget.place['id'] as String;
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await prefs.setStringList('fav_places', set.toList());
    setState(() => _fav = set.contains(id));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    return Scaffold(
      appBar: AppBar(
        title: Text(p['name']),
        actions: [
          IconButton(
            icon: Icon(_fav ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFav,
          ),
        ],
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
            Text(p['desc'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Hướng dẫn (demo)'))),
              child: const Text('Hướng dẫn'),
            ),
          ],
        ),
      ),
    );
  }
}
