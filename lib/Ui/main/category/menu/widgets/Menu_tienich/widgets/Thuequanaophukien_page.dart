import 'package:flutter/material.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/Ui/main/category/business/business_profile_page.dart';
import 'package:http/http.dart' as http;
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/shared_checkout_scaffold.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';

class ThuequanaophukienPage extends StatefulWidget {
  const ThuequanaophukienPage({super.key});

  @override
  State<ThuequanaophukienPage> createState() => _ThuequanaophukienPageState();
}

class _ThuequanaophukienPageState extends State<ThuequanaophukienPage> {
  final Set<String> _favorites = {};
  int _cartCount = 0;

  String? _filterCategory;
  String? _filterSize;

  late Stream<List<Map<String, dynamic>>> _clothesStream;

  @override
  void initState() {
    super.initState();
    _clothesStream = FirebaseBusinessService().streamServices(
      collectionName: 'business_clothes_services',
    );
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
                    children:
                        [
                          'Áo dài',
                          'Váy cưới',
                          'Vest',
                          'Truyền thống',
                          'Khác',
                        ].map((c) {
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
                          setState(() {
                            _filterCategory = selectedCat;
                            _filterSize = selectedSize;
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
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseHistoryPage()),
              );
            },
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
                    builder: (context) => const _ClothesSearchPage(),
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
                        'Tìm kiếm trang phục, phụ kiện...',
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _clothesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Đã có lỗi xảy ra'));
                }
                final items = snapshot.data ?? [];
                final filtered = items.where((it) {
                  final extra = it['extra'] as Map<String, dynamic>? ?? {};
                  final matchesCat =
                      _filterCategory == null ||
                      extra['clothingType'] == _filterCategory;
                  final matchesSize =
                      _filterSize == null ||
                      extra['sizeRange']?.toString().contains(_filterSize!) ==
                          true;
                  return matchesCat && matchesSize && it['status'] == 'active';
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy trang phục phù hợp'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final extra = item['extra'] as Map<String, dynamic>? ?? {};
                    final itemId = item['id'] as String;
                    final isFav = _favorites.contains(itemId);
                    final stockCount =
                        (item['stockCount'] as num?)?.toInt() ??
                        (extra['stockCount'] as num?)?.toInt() ??
                        (item['quantity'] as num?)?.toInt() ??
                        (extra['quantity'] as num?)?.toInt() ??
                        10;
                    final available =
                        stockCount > 0; // Update logic based on stock
                    final imageUrl =
                        extra['imageUrl'] as String? ??
                        'https://images.unsplash.com/photo-1551048662-8dc5f95f4c40?w=800';

                    final ownerId = (item['ownerId'] ?? '').toString();

                    Widget cardWidget = Card(
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
                                Image(
                                  image:
                                      imageUrl.startsWith('http') ||
                                          imageUrl.startsWith('data:image')
                                      ? getImageProvider(imageUrl)!
                                      : AssetImage(imageUrl) as ImageProvider,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey[300]),
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
                                  item['name'] as String? ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['price'] ?? 0}đ',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: available
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      available ? 'Còn: $stockCount' : 'Hết',
                                      style: TextStyle(
                                        color: available
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
                    );

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

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ThueItemDetailPage(item: item),
                          ),
                        );
                      },
                      child: cardWidget,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartPage()),
          );
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Giỏ hàng'),
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
  late Future<List<Map<String, dynamic>>> _similarItemsFuture;

  @override
  void initState() {
    super.initState();
    final extra = widget.item['extra'] as Map<String, dynamic>? ?? {};
    _selectedSize =
        extra['sizeRange']?.toString().split('-').firstOrNull?.trim() ?? 'M';

    // Sử dụng Future thay vì Stream để tránh load lại toàn bộ collection khi có thay đổi,
    // đặc biệt khi collection chứa các chuỗi base64 lớn gây ANR.
    _similarItemsFuture = FirebaseFirestore.instance
        .collection('business_clothes_services')
        .where('status', isEqualTo: 'active')
        .limit(20)
        .get()
        .then((snap) {
          return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });

    final ownerId = widget.item['ownerId']?.toString() ?? '';
    if (ownerId.isNotEmpty) {
      _ownerProfileFuture = FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(ownerId)
          .get();
    }
  }

  Future<DocumentSnapshot>? _ownerProfileFuture;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final extra = it['extra'] as Map<String, dynamic>? ?? {};
    final price = (it['price'] as num?)?.toInt() ?? 0;
    final imageUrl =
        extra['imageUrl'] as String? ??
        'https://images.unsplash.com/photo-1551048662-8dc5f95f4c40?w=800';
    final stockCount =
        (it['stockCount'] as num?)?.toInt() ??
        (extra['stockCount'] as num?)?.toInt() ??
        (it['quantity'] as num?)?.toInt() ??
        (extra['quantity'] as num?)?.toInt() ??
        10;
    final available = stockCount > 0;
    final isOwner =
        FirebaseAuth.instance.currentUser?.uid == it['ownerId']?.toString();

    final images = extra['images'] is List
        ? (extra['images'] as List).map((e) => e.toString()).toList()
        : [imageUrl];

    return Scaffold(
      appBar: AppBar(title: Text(it['name'] as String? ?? 'Chi tiết')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ImageCarousel(images: images),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it['name'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: available ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        available
                            ? 'Số lượng hàng còn: $stockCount'
                            : 'Hết hàng',
                        style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${price}đ',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (it['ownerId'] != null &&
                      it['ownerId'].toString().isNotEmpty) ...[
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
                                  ownerId: it['ownerId'].toString(),
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
                    'Đã thuê: ${(it['soldCount'] as num?)?.toInt() ?? 0}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(it['description'] as String? ?? ''),
                  if (!isOwner)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: available
                                ? () {
                                    ClothesCartManager.addToCart({
                                      'item': it,
                                      'days': _days,
                                      'size': _selectedSize,
                                      'totalPrice': price * _days,
                                    }).then((_) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã thêm vào giỏ thuê'),
                                        ),
                                      );
                                    });
                                  }
                                : null,
                            child: const Text('Thêm vào giỏ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: available
                              ? () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Xác nhận thuê'),
                                      content: Text(
                                        'Bạn muốn thuê "${it['name']}" (x$_days)?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            ); // Pop dialog
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ClothesCheckoutPage(
                                                      items: [
                                                        {
                                                          'item': it,
                                                          'days': _days,
                                                          'size': _selectedSize,
                                                          'totalPrice':
                                                              price * _days,
                                                        },
                                                      ],
                                                      totalBasePrice:
                                                          (price * _days)
                                                              .toDouble(),
                                                      ownerId: it['ownerId']
                                                          .toString(),
                                                      isBuyNow: true,
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
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        ((it['rating'] as num?)?.toDouble() ?? 0.0)
                            .toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${(it['reviewsCount'] as num?)?.toInt() ?? 0} đánh giá)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sản phẩm tương tự',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _similarItemsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());

                      final currentId = it['id']?.toString() ?? '';
                      final currentCat =
                          (it['extra']
                              as Map<String, dynamic>?)?['clothingType'];

                      final similarItems = snapshot.data!
                          .where((item) {
                            if (item['status'] != 'active') return false;
                            if (item['id']?.toString() == currentId)
                              return false;
                            final itemCat =
                                (item['extra']
                                    as Map<String, dynamic>?)?['clothingType'];
                            return itemCat == currentCat ||
                                item['ownerId'] == it['ownerId'];
                          })
                          .take(4)
                          .toList();

                      if (similarItems.isEmpty)
                        return const Text(
                          'Không có sản phẩm tương tự',
                          style: TextStyle(color: Colors.grey),
                        );

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: similarItems.length,
                        itemBuilder: (context, index) {
                          final item = similarItems[index];
                          final extra =
                              item['extra'] as Map<String, dynamic>? ?? {};
                          final imageUrl =
                              extra['imageUrl'] as String? ??
                              'https://images.unsplash.com/photo-1551048662-8dc5f95f4c40?w=800';

                          final ownerId = (item['ownerId'] ?? '').toString();

                          Widget cardWidget = Card(
                            clipBehavior: Clip.hardEdge,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Image(
                                    image:
                                        (imageUrl.startsWith('http') ||
                                            imageUrl.startsWith('data:image'))
                                        ? (getImageProvider(imageUrl) ??
                                              const AssetImage(
                                                'asset/images/anhdemo.jpeg',
                                              ))
                                        : AssetImage(imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: Colors.grey[300]),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] as String? ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['price'] ?? 0}đ',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (ownerId.isNotEmpty) {
                            Widget currentCard = cardWidget;
                            cardWidget =
                                FutureBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>
                                >(
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
                                        businessProfile['isOpen'] as bool? ??
                                        true;
                                    return Opacity(
                                      opacity: isOpen ? 1.0 : 0.5,
                                      child: currentCard,
                                    );
                                  },
                                );
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ThueItemDetailPage(item: item),
                                ),
                              );
                            },
                            child: cardWidget,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartPage()),
          );
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Giỏ hàng'),
      ),
    );
  }
}

class ClothesCartManager {
  static const String _cartKey = 'clothes_cart';
  static const String _historyKey = 'clothes_history';

  static Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_cartKey);
    if (str == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(str));
  }

  static Future<void> addToCart(Map<String, dynamic> item) async {
    final cart = await getCart();
    cart.add(item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cartKey,
      jsonEncode(
        cart,
        toEncodable: (e) {
          if (e is Timestamp) return e.toDate().toIso8601String();
          if (e is DateTime) return e.toIso8601String();
          return e.toString();
        },
      ),
    );
  }

  static Future<void> removeFromCart(int index) async {
    final cart = await getCart();
    if (index >= 0 && index < cart.length) {
      cart.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartKey, jsonEncode(cart));
    }
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static Future<void> checkout() async {
    final cart = await getCart();
    if (cart.isEmpty) return;
    await addHistory(cart);
    await clearCart();
  }

  static Future<void> addHistory(List<Map<String, dynamic>> items) async {
    final history = await getHistory();
    final now = DateTime.now().toIso8601String();
    history.addAll(items.map((item) => {...item, 'date': now}));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_historyKey);
    if (str == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(str));
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await ClothesCartManager.getCart();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _checkout() {
    if (_items.isEmpty) return;

    double total = _items.fold(
      0,
      (sum, item) => sum + (item['totalPrice'] as num),
    );

    String ownerId = '';
    final firstItem = _items.first['item'] as Map<String, dynamic>? ?? {};
    ownerId = firstItem['ownerId']?.toString() ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClothesCheckoutPage(
          items: _items,
          totalBasePrice: total,
          ownerId: ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    double total = _items.fold(
      0,
      (sum, item) => sum + (item['totalPrice'] as num),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: _items.isEmpty
          ? const Center(child: Text('Giỏ hàng trống'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final cartItem = _items[index];
                      final it = cartItem['item'] as Map<String, dynamic>;
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: (it['extra']?['imageUrl'] != null)
                              ? Image(
                                  image:
                                      getImageProvider(
                                        it['extra']['imageUrl'],
                                      ) ??
                                      const AssetImage(
                                            'assets/images/placeholder.jpg',
                                          )
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image),
                        ),
                        title: Text(it['name'] ?? 'Sản phẩm'),
                        subtitle: Text(
                          'Size: ${cartItem['size']} - Số lượng: ${cartItem['days']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cartItem['totalPrice']}đ',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await ClothesCartManager.removeFromCart(index);
                                _loadCart();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng: ${total}đ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _checkout,
                        child: const Text('Thanh toán'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class ClothesCheckoutPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double totalBasePrice;
  final String ownerId;
  final bool isBuyNow;

  const ClothesCheckoutPage({
    super.key,
    required this.items,
    required this.totalBasePrice,
    required this.ownerId,
    this.isBuyNow = false,
  });

  @override
  Widget build(BuildContext context) {
    return SharedCheckoutScaffold(
      title: 'Xác nhận thuê đồ',
      ownerId: ownerId,
      basePrice: totalBasePrice,
      itemNameSummary: '(${items.length} sản phẩm)',
      requireAddress: true,
      allowReceiveAtLocation: true,
      onSubmit: (finalPrice, extraInfo) async {
        String detailNames = items
            .map((cartItem) {
              final it = cartItem['item'] as Map<String, dynamic>;
              return '${it['name']} (Size: ${cartItem['size']}, ${cartItem['days']} ngày)';
            })
            .join(', ');

        await FirebaseMenuService().createOrder(
          storeName: 'Dịch vụ thuê đồ',
          itemName: 'Thuê ${items.length} sản phẩm: $detailNames $extraInfo',
          price: finalPrice,
          itemImage: '',
          quantity: 1,
          status: 'Chờ xác nhận',
          ownerId: ownerId,
          type: 'clothes_rental',
        );

        if (!isBuyNow) {
          await ClothesCartManager.checkout();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đặt thuê thành công!')));
          Navigator.pop(context);
          Navigator.pop(context);
        }
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sản phẩm trong giỏ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.map((cartItem) {
            final it = cartItem['item'] as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: (it['extra']?['imageUrl'] != null)
                      ? Image(
                          image:
                              getImageProvider(it['extra']['imageUrl']) ??
                              const AssetImage('assets/images/placeholder.jpg')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image),
                ),
                title: Text(it['name'] ?? 'Sản phẩm'),
                subtitle: Text(
                  'Size: ${cartItem['size']} - Số lượng: ${cartItem['days']}',
                ),
                trailing: Text(
                  '${cartItem['totalPrice']}đ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});
  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await ClothesCartManager.getHistory();
    items.sort((a, b) {
      final da =
          DateTime.tryParse(a['date'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db =
          DateTime.tryParse(b['date'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lịch sử mua')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử mua')),
      body: _items.isEmpty
          ? const Center(child: Text('Chưa có lịch sử mua hàng'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final historyItem = _items[index];
                final it = historyItem['item'] as Map<String, dynamic>;
                final date =
                    DateTime.tryParse(historyItem['date'] ?? '') ??
                    DateTime.now();
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: (it['extra']?['imageUrl'] != null)
                          ? Image(
                              image:
                                  getImageProvider(it['extra']['imageUrl']) ??
                                  const AssetImage(
                                        'assets/images/placeholder.jpg',
                                      )
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image),
                    ),
                    title: Text(it['name'] ?? 'Sản phẩm'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Size: ${historyItem['size']} - Số lượng: ${historyItem['days']}',
                        ),
                        Text(
                          'Ngày: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${historyItem['totalPrice']}đ',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ClothesSearchPage extends StatefulWidget {
  const _ClothesSearchPage();

  @override
  State<_ClothesSearchPage> createState() => _ClothesSearchPageState();
}

class _ClothesSearchPageState extends State<_ClothesSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _history = [];
  bool _hasSubmitted = false;
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadItems() {
    FirebaseBusinessService()
        .streamServices(collectionName: 'business_clothes_services')
        .listen((items) {
          if (!mounted) return;
          setState(() {
            _allItems = items.where((it) => it['status'] == 'active').toList();
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
        _history = prefs.getStringList('clothes_search_history') ?? [];
      });
    }
  }

  Future<void> _saveHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(query);
    _history.insert(0, query);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setStringList('clothes_search_history', _history);
    if (mounted) setState(() {});
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('clothes_search_history');
    if (mounted) setState(() => _history.clear());
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allItems.where((it) {
        final name = (it['name'] ?? '').toString().toLowerCase();
        return q.isEmpty || name.contains(q);
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
            hintText: 'Tìm kiếm trang phục, phụ kiện...',
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
                      'Không tìm thấy sản phẩm nào',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  final extra = item['extra'] as Map<String, dynamic>? ?? {};
                  final itemId = item['id'] as String;
                  final isFav = _favorites.contains(itemId);
                  final stockCount =
                      (item['stockCount'] as num?)?.toInt() ??
                      (extra['stockCount'] as num?)?.toInt() ??
                      (item['quantity'] as num?)?.toInt() ??
                      (extra['quantity'] as num?)?.toInt() ??
                      10;
                  final available = stockCount > 0;
                  final imageUrl =
                      extra['imageUrl'] as String? ??
                      'https://images.unsplash.com/photo-1551048662-8dc5f95f4c40?w=800';

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
                                Image(
                                  image:
                                      imageUrl.startsWith('http') ||
                                          imageUrl.startsWith('data:image')
                                      ? (getImageProvider(imageUrl) ??
                                            const AssetImage(
                                                  'asset/images/anhdemo.jpeg',
                                                )
                                                as ImageProvider)
                                      : AssetImage(imageUrl) as ImageProvider,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey[300]),
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
                                  item['name'] as String? ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['price'] ?? 0}đ',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: available
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      available ? 'Còn: $stockCount' : 'Hết',
                                      style: TextStyle(
                                        color: available
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
    );
  }
}
