import 'package:flutter/material.dart';

class ThuequanaophukienPage extends StatefulWidget {
  const ThuequanaophukienPage({super.key});

  @override
  State<ThuequanaophukienPage> createState() => _ThuequanaophukienPageState();
}

class _ThuequanaophukienPageState extends State<ThuequanaophukienPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _items = List.generate(
    24,
    (i) => {
      'id': i,
      'title': i % 2 == 0 ? 'Áo Vintage ${i + 1}' : 'Đầm Dạ Hội ${i + 1}',
      'category': i % 2 == 0 ? 'Áo' : 'Đầm',
      'pricePerDay': (50 + (i * 5)).toDouble(),
      'image': 'asset/images/anhdemo.jpeg',
      'size': (i % 3 == 0)
          ? 'S'
          : (i % 3 == 1)
          ? 'M'
          : 'L',
      'available': i % 5 != 0,
      'description':
          'Trang phục đẹp, giữ form tốt, phù hợp sự kiện và chụp ảnh.',
    },
  );

  List<Map<String, dynamic>> _filtered = [];
  final Set<int> _favorites = {};
  int _cartCount = 0;

  String? _filterCategory;
  String? _filterSize;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_items);
    _searchController.addListener(_applyFilters);
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _items.where((it) {
        final matchesQ =
            q.isEmpty || it['title'].toString().toLowerCase().contains(q);
        final matchesCat =
            _filterCategory == null || it['category'] == _filterCategory;
        final matchesSize = _filterSize == null || it['size'] == _filterSize;
        return matchesQ && matchesCat && matchesSize;
      }).toList();
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        String? selectedCat = _filterCategory;
        String? selectedSize = _filterSize;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lọc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('Danh mục'),
                  Wrap(
                    spacing: 8,
                    children: ['Áo', 'Đầm', 'Phụ kiện'].map((c) {
                      final selected = selectedCat == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (v) =>
                            setStateSheet(() => selectedCat = v ? c : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Size'),
                  Wrap(
                    spacing: 8,
                    children: ['S', 'M', 'L', 'XL'].map((s) {
                      final selected = selectedSize == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (v) =>
                            setStateSheet(() => selectedSize = v ? s : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _filterCategory = selectedCat;
                          _filterSize = selectedSize;
                          Navigator.pop(context);
                          _applyFilters();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuê quần áo & phụ kiện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Giỏ hàng chưa có chức năng')),
                  );
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm trang phục, phụ kiện...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final item = _filtered[index];
                final isFav = _favorites.contains(item['id'] as int);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThueItemDetailPage(item: item),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                item['image'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[300]),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isFav)
                                        _favorites.remove(item['id'] as int);
                                      else
                                        _favorites.add(item['id'] as int);
                                    });
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white70,
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav ? Colors.red : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '${item['pricePerDay'].toStringAsFixed(0)}k / ngày',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: (item['available'] as bool)
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (item['available'] as bool) ? 'Còn' : 'Hết',
                                    style: TextStyle(
                                      color: (item['available'] as bool)
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_filtered.isNotEmpty) {
            setState(() => _cartCount += 1);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ')));
          }
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Thêm tạm'),
      ),
    );
  }
}

class ThueItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ThueItemDetailPage({super.key, required this.item});

  @override
  State<ThueItemDetailPage> createState() => _ThueItemDetailPageState();
}

class _ThueItemDetailPageState extends State<ThueItemDetailPage> {
  int _days = 1;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.item['size'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final price = (it['pricePerDay'] as double).toInt();
    return Scaffold(
      appBar: AppBar(title: Text(it['title'] as String)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                it['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(it['description'] as String),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.green),
                      const SizedBox(width: 6),
                      Text((it['available'] as bool) ? 'Còn hàng' : 'Hết hàng'),
                      const Spacer(),
                      Text(
                        '${price}k / ngày',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Kích cỡ'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['S', 'M', 'L', 'XL'].map((s) {
                      final sel = _selectedSize == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: sel,
                        onSelected: it['available'] == true
                            ? (v) {
                                setState(() => _selectedSize = v ? s : null);
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Số ngày thuê'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          if (_days > 1) _days--;
                        }),
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_days'),
                      IconButton(
                        onPressed: () => setState(() => _days++),
                        icon: const Icon(Icons.add),
                      ),
                      const Spacer(),
                      Text(
                        'Tổng: ${price * _days}k',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((it['experience'] as String?) != null) ...[
                    const Text(
                      'Kinh nghiệm',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(it['experience'] as String),
                    const SizedBox(height: 12),
                  ],
                  if ((it['itinerary'] as String?) != null) ...[
                    const Text(
                      'Lịch trình',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(it['itinerary'] as String),
                    const SizedBox(height: 12),
                  ],
                  if ((it['expenses'] as String?) != null) ...[
                    const Text(
                      'Chi tiêu',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(it['expenses'] as String),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: it['available'] == true
                              ? () {
                                  setState(() {
                                    /* add to cart logic */
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã thêm vào giỏ thuê'),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Thêm vào giỏ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: it['available'] == true
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Xác nhận thuê'),
                                    content: Text(
                                      'Bạn muốn thuê "${it['title']}" trong $_days ngày?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Thuê thành công (giả lập)',
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Xác nhận'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        child: const Text('Thuê ngay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
