import 'package:flutter/material.dart';

String formatCurrency(int v) =>
    '${v.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')} đ';

class Photographer {
  final String id;
  final String name;
  final String location;
  final double rating;
  final int pricePerHour;
  final String imageUrl;
  final String description;
  final int experienceYears;
  final List<String> availability;
  final Map<String, int> pricing;

  Photographer({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.pricePerHour,
    required this.imageUrl,
    required this.description,
    required this.experienceYears,
    required this.availability,
    required this.pricing,
  });
}

final List<Photographer> mockPhotographers = [
  Photographer(
    id: 'p1',
    name: 'Nguyễn Văn A',
    location: 'Hà Nội',
    rating: 4.8,
    pricePerHour: 500000,
    imageUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
    description:
        'Thợ chụp chuyên nghiệp, có kinh nghiệm chụp cưới, sự kiện và studio. Mang theo thiết bị cao cấp và phong cách nhẹ nhàng.',
    experienceYears: 8,
    availability: ['T2-T6: 9:00-18:00', 'T7: 8:00-20:00'],
    pricing: {
      'Giá/giờ': 500000,
      'Phí di chuyển': 100000,
      'Hậu kỳ (tùy chọn)': 150000,
    },
  ),
  Photographer(
    id: 'p2',
    name: 'Trần Thị B',
    location: 'Hồ Chí Minh',
    rating: 4.6,
    pricePerHour: 450000,
    imageUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
    description:
        'Đa phong cách: từ đời thường đến thời trang. Hậu kỳ nhanh, phong cách màu sắc tươi sáng.',
    experienceYears: 5,
    availability: ['T2-T7: 10:00-19:00'],
    pricing: {'Giá/giờ': 450000, 'Phí di chuyển': 80000},
  ),
  Photographer(
    id: 'p3',
    name: 'Lê Văn C',
    location: 'Đà Nẵng',
    rating: 4.9,
    pricePerHour: 650000,
    imageUrl:
        'https://images.unsplash.com/photo-1507120410856-1f35574c3b45?w=800',
    description:
        'Photographer hướng tới cảm xúc, chuyên chụp ngoại cảnh và phóng sự cưới. Chuyên nghiệp và thân thiện.',
    experienceYears: 10,
    availability: ['T2-T6: 8:00-17:00', 'T7: 7:00-21:00'],
    pricing: {
      'Giá/giờ': 650000,
      'Phí di chuyển': 120000,
      'Phí chụp ngoại cảnh': 200000,
    },
  ),
];

class ThuethochupanhPage extends StatefulWidget {
  const ThuethochupanhPage({super.key});

  @override
  State<ThuethochupanhPage> createState() => _ThuethochupanhPageState();
}

class _ThuethochupanhPageState extends State<ThuethochupanhPage> {
  String _search = '';
  String _selectedFilter = 'Tất cả';
  String _sortBy = 'Mặc định';

  List<Photographer> get filtered {
    final q = _search.toLowerCase();
    var list = mockPhotographers.where((p) {
      final matchesQuery =
          p.name.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
      final matchesFilter =
          _selectedFilter == 'Tất cả' || p.location == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();

    if (_sortBy == 'Giá: thấp → cao') {
      list.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    } else if (_sortBy == 'Đánh giá') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  final List<String> _locations = [
    'Tất cả',
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
  ];
  final List<String> _sortOptions = ['Mặc định', 'Giá: thấp → cao', 'Đánh giá'];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxis = width > 800 ? 3 : (width > 500 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuê thợ chụp ảnh'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilters(),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return _PhotographerCard(
                      photographer: p,
                      onTap: () => _openDetail(p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Tìm tên hoặc địa điểm',
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.grey),
            itemBuilder: (_) => _sortOptions
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
            onSelected: (s) => setState(() => _sortBy = s),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: _locations.map((loc) {
        final selected =
            _selectedFilter == loc ||
            (loc == 'Tất cả' && _selectedFilter == 'Tất cả');
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(loc),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFilter = loc),
            selectedColor: Colors.deepPurple.shade100,
          ),
        );
      }).toList(),
    );
  }

  void _openDetail(Photographer p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotographerDetailPage(photographer: p),
      ),
    );
  }
}

class _PhotographerCard extends StatelessWidget {
  final Photographer photographer;
  final VoidCallback onTap;

  const _PhotographerCard({
    required this.photographer,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: photographer.id,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(photographer.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photographer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${photographer.experienceYears} năm kinh nghiệm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              photographer.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            photographer.rating.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${photographer.pricePerHour.toString().replaceAllMapped(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), (m) => '.')} đ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

class PhotographerDetailPage extends StatelessWidget {
  final Photographer photographer;

  const PhotographerDetailPage({required this.photographer, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(photographer.name),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: photographer.id,
              child: Image.network(
                photographer.imageUrl,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photographer.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.place,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                photographer.location,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 6),
                              Text(photographer.rating.toString()),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${photographer.pricePerHour.toString().replaceAllMapped(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), (m) => '.')} đ/giờ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    photographer.description,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.work,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${photographer.experienceYears} năm kinh nghiệm',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lịch trình',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: photographer.availability
                        .map((a) => Chip(label: Text(a)))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chi tiêu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Column(
                        children: photographer.pricing.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key),
                                    Text(formatCurrency(e.value)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.message),
                          label: const Text('Nhắn tin'),
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tính năng nhắn tin tạm thời chưa hỗ trợ',
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.event_available),
                          label: const Text('Đặt lịch'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: BookingForm(photographer: photographer),
                            ),
                          ),
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
  }
}

class BookingForm extends StatefulWidget {
  final Photographer photographer;

  const BookingForm({required this.photographer, super.key});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Đặt lịch với ${widget.photographer.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên của bạn'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  validator: (v) => v == null || v.length < 9
                      ? 'Số điện thoại không hợp lệ'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickDate,
                        child: Text(
                          _date == null
                              ? 'Chọn ngày'
                              : '${_date!.day}/${_date!.month}/${_date!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickTime,
                        child: Text(
                          _time == null ? 'Chọn giờ' : _time!.format(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Xác nhận đặt lịch'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày và giờ')),
      );
      return;
    }

    final datetime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          'Đặt lịch thành công với ${widget.photographer.name} vào ${datetime.day}/${datetime.month}/${datetime.year} - ${_time!.format(context)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
