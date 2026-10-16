import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/Ui/main/category/business/business_profile_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Thuethochupanh_booking.dart';

String formatCurrency(int v) =>
    '${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ';

class Photographer {
  final String id;
  final String ownerId;
  final String name;
  final String location;
  final double rating;
  final int pricePerHour;
  final String imageUrl;
  final String description;
  final int experienceYears;
  final List<String> availability;
  final Map<String, dynamic> pricing;
  final List<String> images;
  final int reviews;
  final List<Map<String, dynamic>> reviewsList;
  final int orderCount;

  Photographer({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.location,
    required this.rating,
    required this.pricePerHour,
    required this.imageUrl,
    required this.description,
    required this.experienceYears,
    required this.availability,
    required this.pricing,
    required this.images,
    required this.reviews,
    required this.reviewsList,
    required this.orderCount,
  });
}

class ThuethochupanhPage extends StatefulWidget {
  const ThuethochupanhPage({super.key});

  @override
  State<ThuethochupanhPage> createState() => _ThuethochupanhPageState();
}

class _ThuethochupanhPageState extends State<ThuethochupanhPage> {
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
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DonHangCuaBanPage(
                    serviceType: 'photographer_rental',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử đặt',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseBusinessService().streamServices(
                    collectionName: 'business_photographer_services',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data ?? [];
                    final photographers = items
                        .where((it) => it['status'] == 'active')
                        .map((it) {
                          final extra =
                              it['extra'] as Map<String, dynamic>? ?? {};
                          return Photographer(
                            id: it['id'] as String,
                            ownerId: (it['ownerId'] ?? '').toString(),
                            name: it['name'] as String? ?? 'Thợ chụp ảnh',
                            location: it['address'] as String? ?? '',
                            rating:
                                (extra['rating'] as num?)?.toDouble() ?? 0.0,
                            reviews: (extra['reviews'] as num?)?.toInt() ?? 0,
                            reviewsList: extra['reviewsList'] is List
                                ? List<Map<String, dynamic>>.from(
                                    extra['reviewsList'],
                                  )
                                : <Map<String, dynamic>>[],
                            pricePerHour: (it['price'] as num?)?.toInt() ?? 0,
                            imageUrl:
                                extra['imageUrl'] as String? ??
                                'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
                            description: it['description'] as String? ?? '',
                            experienceYears:
                                (extra['experienceYears'] as num?)?.toInt() ??
                                0,
                            availability: extra['availability'] is List
                                ? (extra['availability'] as List)
                                      .map((e) => e.toString())
                                      .toList()
                                : ['Tất cả các ngày'],
                            pricing: {
                              'Giá/giờ': (it['price'] as num?)?.toInt() ?? 0,
                              'Gói': extra['package'] ?? 'N/A',
                              'Phong cách': extra['style'] ?? 'Đa dạng',
                            },
                            images: extra['images'] is List
                                ? (extra['images'] as List)
                                      .map((e) => e.toString())
                                      .toList()
                                : [
                                    extra['imageUrl'] as String? ??
                                        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
                                  ],
                            orderCount:
                                (it['orderCount'] as num?)?.toInt() ??
                                (extra['orderCount'] as num?)?.toInt() ??
                                0,
                          );
                        })
                        .toList();

                    var filtered = photographers.toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('Không tìm thấy thợ chụp ảnh nào.'),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        childAspectRatio: 3 / 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        Widget cardWidget = _PhotographerCard(
                          photographer: p,
                          onTap: () => _openDetail(p),
                        );

                        final ownerId = p.ownerId;
                        if (ownerId.isNotEmpty) {
                          Widget currentCard = cardWidget;
                          cardWidget =
                              StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>
                              >(
                                stream: FirebaseFirestore.instance
                                    .collection('user_profiles')
                                    .doc(ownerId)
                                    .snapshots(),
                                builder: (context, profileSnap) {
                                  final profileData =
                                      profileSnap.data?.data() ?? {};
                                  final businessProfile =
                                      (profileData['businessProfile']
                                          as Map<String, dynamic>?) ??
                                      {};
                                  final isOpen =
                                      businessProfile['isOpen'] as bool? ??
                                      true;
                                  return Opacity(
                                    opacity: isOpen ? 1.0 : 0.5,
                                    child: currentCard,
                                  );
                                },
                              );
                        }

                        return cardWidget;
                      },
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const _PhotographerSearchPage(),
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
            const Icon(Icons.search, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tìm tên hoặc địa điểm',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
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
                      image:
                          getImageProvider(photographer.imageUrl) ??
                          const AssetImage('assets/images/placeholder.jpg')
                              as ImageProvider,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                            Expanded(
                              child: Text(
                                photographer.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        '${photographer.pricePerHour.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
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

class PhotographerDetailPage extends StatefulWidget {
  final Photographer photographer;

  const PhotographerDetailPage({required this.photographer, super.key});

  @override
  State<PhotographerDetailPage> createState() => _PhotographerDetailPageState();
}

class _PhotographerDetailPageState extends State<PhotographerDetailPage> {
  bool _isBusy = false;
  bool _loadingBusy = true;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('photographer_orders')
          .where('photographerId', isEqualTo: widget.photographer.id)
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

  @override
  Widget build(BuildContext context) {
    final photographer = widget.photographer;
    final isOwner =
        FirebaseAuth.instance.currentUser?.uid == photographer.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(photographer.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 260,
              child: ImageCarousel(images: photographer.images),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
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
                                Expanded(
                                  child: Text(
                                    photographer.location,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                            '${photographer.pricePerHour.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ/giờ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (photographer.ownerId.isNotEmpty) ...[
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('user_profiles')
                          .doc(photographer.ownerId)
                          .get(),
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
                                  ownerId: photographer.ownerId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
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
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã đặt: ${photographer.orderCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
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
                                    Expanded(child: Text(e.key)),
                                    Text(
                                      e.value is num
                                          ? formatCurrency(e.value as int)
                                          : e.value.toString(),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đánh giá',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (photographer.reviewsList.isEmpty)
                    const Text('Chưa có đánh giá nào.')
                  else
                    ...photographer.reviewsList.map((r) {
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
                                      (r['author'] as String?)
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'U',
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
                                              r['author'] as String? ?? 'User',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 14,
                                                  color: Colors.amber,
                                                ),
                                                Text(
                                                  ' ${(r['rating'] as num?)?.toDouble() ?? 5.0}',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(r['text'] as String? ?? ''),
                                        const SizedBox(height: 8),
                                        Text(
                                          r['date'] as String? ?? '',
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
                    }).toList(),
                  const SizedBox(height: 20),
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _loadingBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.event_available,
                                color: Colors.white,
                              ),
                        label: Text(
                          _loadingBusy
                              ? 'Đang kiểm tra...'
                              : (_isBusy ? 'Đang bận' : 'Đặt lịch'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isBusy
                              ? Colors.grey
                              : Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _loadingBusy || _isBusy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PhotographerBookingPage(
                                    photographer: photographer,
                                    onSuccess: _checkAvailability,
                                  ),
                                ),
                              ),
                      ),
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

class _PhotographerSearchPage extends StatefulWidget {
  const _PhotographerSearchPage();

  @override
  State<_PhotographerSearchPage> createState() =>
      _PhotographerSearchPageState();
}

class _PhotographerSearchPageState extends State<_PhotographerSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Photographer> _allItems = [];
  List<Photographer> _filtered = [];
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
    FirebaseBusinessService()
        .streamServices(collectionName: 'business_photographer_services')
        .listen((items) {
          if (!mounted) return;
          final photographers = items.where((it) => it['status'] == 'active').map((
            it,
          ) {
            final extra = it['extra'] as Map<String, dynamic>? ?? {};
            return Photographer(
              id: it['id'] as String,
              ownerId: (it['ownerId'] ?? '').toString(),
              name: it['name'] as String? ?? 'Thợ chụp ảnh',
              location: it['address'] as String? ?? '',
              rating: (extra['rating'] as num?)?.toDouble() ?? 0.0,
              reviews: (extra['reviews'] as num?)?.toInt() ?? 0,
              reviewsList: extra['reviewsList'] is List
                  ? List<Map<String, dynamic>>.from(extra['reviewsList'])
                  : <Map<String, dynamic>>[],
              pricePerHour: (it['price'] as num?)?.toInt() ?? 0,
              imageUrl:
                  extra['imageUrl'] as String? ??
                  'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
              description: it['description'] as String? ?? '',
              experienceYears: (extra['experienceYears'] as num?)?.toInt() ?? 0,
              availability: extra['availability'] is List
                  ? (extra['availability'] as List)
                        .map((e) => e.toString())
                        .toList()
                  : ['Tất cả các ngày'],
              pricing: {
                'Giá/giờ': (it['price'] as num?)?.toInt() ?? 0,
                'Gói': extra['package'] ?? 'N/A',
                'Phong cách': extra['style'] ?? 'Đa dạng',
              },
              images: extra['images'] is List
                  ? (extra['images'] as List).map((e) => e.toString()).toList()
                  : [
                      extra['imageUrl'] as String? ??
                          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
                    ],
              orderCount:
                  (it['orderCount'] as num?)?.toInt() ??
                  (extra['orderCount'] as num?)?.toInt() ??
                  0,
            );
          }).toList();
          setState(() {
            _allItems = photographers;
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
        _history = prefs.getStringList('photographer_search_history') ?? [];
      });
    }
  }

  Future<void> _saveHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setStringList('photographer_search_history', _history);
    if (mounted) setState(() {});
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('photographer_search_history');
    if (mounted) setState(() => _history.clear());
  }

  void _removeHistoryItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(item);
    await prefs.setStringList('photographer_search_history', _history);
    if (mounted) setState(() {});
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allItems.where((it) {
        final matchesQ =
            q.isEmpty ||
            it.name.toLowerCase().contains(q) ||
            it.location.toLowerCase().contains(q);
        return matchesQ;
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
            hintText: 'Tìm thợ hoặc địa điểm',
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
                      'Không tìm thấy thợ chụp ảnh nào',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final p = _filtered[index];
                  return _PhotographerCard(
                    photographer: p,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PhotographerDetailPage(photographer: p),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
