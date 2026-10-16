import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';

import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tourn/Ui/main/category/messenge/pages/ChatPage.dart';
import 'package:tourn/Ui/main/category/business/business_account_action.dart';
import 'package:tourn/Ui/main/category/business/business_onboarding_helper.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DimIfClosed extends StatelessWidget {
  final String ownerId;
  final Widget child;

  const DimIfClosed({super.key, required this.ownerId, required this.child});

  @override
  Widget build(BuildContext context) {
    if (ownerId.isEmpty) return child;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        final profileData = snapshot.data?.data() ?? {};
        final businessProfile =
            (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
        final isOpen = businessProfile['isOpen'] as bool? ?? true;
        return Opacity(opacity: isOpen ? 1.0 : 0.5, child: child);
      },
    );
  }
}

class AmthucvungmienPage extends StatefulWidget {
  const AmthucvungmienPage({super.key});

  @override
  State<AmthucvungmienPage> createState() => _AmthucvungmienPageState();
}

class _CollectionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Color brandOrange;
  final Color brandGreen;
  final Color pageBg;

  const _CollectionsPage({
    required this.items,
    required this.brandOrange,
    required this.brandGreen,
    required this.pageBg,
  });

  Widget _buildImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, size: 32, color: Colors.grey),
      );
    }
    final isNetwork =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('data:image');
    return Image(
      image: isNetwork
          ? (getImageProvider(imageUrl) ?? AssetImage(imageUrl))
                as ImageProvider
          : AssetImage(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> collections = {};
    final Map<String, int> counts = {};
    for (final item in items) {
      final category = item['category'] as String;
      collections.putIfAbsent(category, () => item);
      counts[category] = (counts[category] ?? 0) + 1;
    }
    final entries = collections.entries.toList();
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        elevation: 0,
        title: Text(
          'Bộ sưu tập',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final count = counts[entry.key] ?? 0;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final filtered = items
                  .where((item) => item['category'] == entry.key)
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _FoodListPage(
                    title: entry.key,
                    items: filtered,
                    brandOrange: brandOrange,
                    brandGreen: brandGreen,
                    pageBg: pageBg,
                    cardBg: Colors.white,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: _buildImage(entry.value['image'] as String),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count món',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
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
    );
  }
}

class _FoodListPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Color brandOrange;
  final Color brandGreen;
  final Color pageBg;
  final Color cardBg;

  const _FoodListPage({
    required this.title,
    required this.items,
    required this.brandOrange,
    required this.brandGreen,
    required this.pageBg,
    required this.cardBg,
  });

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  Widget _buildTag(String text, {Color? color, Color? bg}) {
    final chipColor = color ?? brandOrange;
    final chipBg = bg ?? chipColor.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, size: 32, color: Colors.grey),
      );
    }
    final isNetwork =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('data:image');
    return Image(
      image: isNetwork
          ? (getImageProvider(imageUrl) ?? AssetImage(imageUrl))
                as ImageProvider
          : AssetImage(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FoodDetailPage(
          item: item,
          brandOrange: brandOrange,
          brandGreen: brandGreen,
          pageBg: pageBg,
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    final ownerId = (item['ownerId'] ?? '').toString();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        final profileData = snapshot.data?.data() ?? {};
        final businessProfile =
            (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
        final isOpen = businessProfile['isOpen'] as bool? ?? true;

        return Opacity(
          opacity: isOpen ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetail(context, item),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: 118,
                      height: 118,
                      child: _buildImage(item['image'] as String),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildTag(
                                item['region'] as String,
                                color: brandGreen,
                                bg: brandGreen.withOpacity(0.12),
                              ),
                              _buildTag(
                                item['category'] as String,
                                color: brandOrange,
                                bg: brandOrange.withOpacity(0.12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['description'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: brandOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _formatCurrency(item['price'] as double),
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (context) {
                                  final qty =
                                      item['stockQuantity'] as int? ?? -1;
                                  final inStock = qty != 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: inStock
                                          ? Colors.green.withOpacity(0.12)
                                          : Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      inStock
                                          ? (qty > 0 ? 'Còn $qty' : 'Còn hàng')
                                          : 'Hết hàng',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: inStock
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => _buildItemCard(context, items[index]),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }
}

class _FoodDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color brandOrange;
  final Color brandGreen;
  final Color pageBg;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  _FoodDetailPage({
    required this.item,
    required this.brandOrange,
    required this.brandGreen,
    required this.pageBg,
  });

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
      );
    }
    final isNetwork =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('data:image');
    return Image(
      image: isNetwork
          ? (getImageProvider(imageUrl) ?? AssetImage(imageUrl))
                as ImageProvider
          : AssetImage(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSellerCard(BuildContext context) {
    final ownerId = (item['ownerId'] ?? '').toString();
    if (ownerId.isEmpty) return const SizedBox.shrink();

    // Kiểm tra xem người xem có phải chủ sản phẩm không
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == ownerId;

    final repo = context.read<UserRepository>();
    return StreamBuilder<UserModel?>(
      stream: repo.streamUser(ownerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isOnline = user?.isOnline == true;

        // Lấy tên cửa hàng và avatar từ user_profiles
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('user_profiles')
              .doc(ownerId)
              .snapshots(),
          builder: (context, profileSnap) {
            final profileData = profileSnap.data?.data() ?? {};
            final businessProfile =
                (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
            final media =
                (businessProfile['media'] as Map<String, dynamic>?) ?? {};

            // Tên cửa hàng
            final storeName = (businessProfile['name'] as String?)?.trim();
            final displayName = (storeName != null && storeName.isNotEmpty)
                ? storeName
                : (user?.displayName.isNotEmpty == true
                      ? user!.displayName
                      : 'Cửa hàng');

            // Avatar cửa hàng
            final avatarPath = (media['avatarPath'] as String?)?.trim();
            final avatarUrl = (media['avatar'] as String?)?.trim();
            final avatarFileExists =
                !kIsWeb &&
                avatarPath != null &&
                avatarPath.isNotEmpty &&
                File(avatarPath).existsSync();

            final ImageProvider? avatarProvider = avatarFileExists
                ? FileImage(File(avatarPath!))
                : ((avatarUrl != null && avatarUrl.isNotEmpty)
                      ? getImageProvider(avatarUrl) as ImageProvider?
                      : (user?.photoUrl?.isNotEmpty == true
                            ? getImageProvider(user!.photoUrl!)
                                  as ImageProvider?
                            : null));

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: brandOrange.withValues(alpha: 0.12),
                        backgroundImage: avatarProvider,
                        child: avatarProvider == null
                            ? const Icon(Icons.store, color: Colors.orange)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: isOnline
                                    ? Colors.green
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
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

  Future<void> _addToCart(BuildContext context, {bool navigate = false}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm giỏ hàng.')),
      );
      return;
    }

    final itemId = (item['id'] ?? '').toString();
    if (itemId.isEmpty) return;

    final unitStr = (item['unit'] != null && item['unit'].toString().isNotEmpty)
        ? item['unit'].toString()
        : 'suất';

    int selectedQuantity = 1;
    final maxQty = item['stockQuantity'] as int? ?? 99;

    if (!context.mounted) return;

    final proceed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chọn số lượng',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: selectedQuantity > 1
                              ? () => setModalState(() => selectedQuantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.orange,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$selectedQuantity $unitStr',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: (maxQty <= 0 || selectedQuantity < maxQty)
                              ? () => setModalState(() => selectedQuantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.orange,
                          iconSize: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          navigate ? 'Mua ngay' : 'Thêm vào giỏ',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (proceed != true) return;

    final ref = _firestore
        .collection('food_carts')
        .doc(uid)
        .collection('items')
        .doc(itemId);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          tx.update(ref, {
            'quantity': FieldValue.increment(selectedQuantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(ref, {
            'itemId': itemId,
            'name': item['name'],
            'price': item['price'],
            'image': item['image'],
            'ownerId': item['ownerId'],
            'quantity': selectedQuantity,
            'unit': unitStr,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (!context.mounted) return;
      if (navigate) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const _FoodCartPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewStream() {
    final itemId = (item['id'] ?? '').toString();
    if (itemId.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore
        .collection('food_reviews')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> _canReview() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final itemId = (item['id'] ?? '').toString();
    if (itemId.isEmpty) return false;
    final snap = await _firestore
        .collection('food_orders')
        .where('userId', isEqualTo: uid)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Widget _buildRatingStars(double rating, {double size = 14}) {
    final stars = List.generate(5, (index) {
      final filled = rating >= index + 1;
      final half = rating > index && rating < index + 1;
      return Icon(
        half ? Icons.star_half : Icons.star,
        size: size,
        color: filled || half ? Colors.amber : Colors.grey.shade300,
      );
    });
    return Row(children: stars);
  }

  Future<void> _openReviewDialog(BuildContext context) async {
    final canReview = await _canReview();
    if (!context.mounted) return;

    if (!canReview) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Chưa thể đánh giá',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Bạn cần đặt và nhận món thành công trước khi có thể viết đánh giá.\n\nThương mại lành mạnh bắt đầu từ những đánh giá thật!',
            style: GoogleFonts.beVietnamPro(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DonHangCuaBanPage(serviceType: 'food'),
                  ),
                );
              },
            ),
          ],
        ),
      );
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final itemId = (item['id'] ?? '').toString();
    if (itemId.isEmpty) return;

    final reviewId = '${itemId}_$uid';
    final reviewRef = _firestore.collection('food_reviews').doc(reviewId);
    final existing = await reviewRef.get();
    int rating = (existing.data()?['rating'] as int?) ?? 5;
    final textController = TextEditingController(
      text: (existing.data()?['comment'] as String?) ?? '',
    );

    const starLabels = [
      'Tệ quá',
      'Không hài lòng',
      'Bình thường',
      'Hài lòng',
      'Tuyệt vời',
    ];

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final charCount = textController.text.length;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Đánh giá sản phẩm',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên món
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (item['name'] as String),
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sao đánh giá
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starIndex = index + 1;
                              return GestureDetector(
                                onTap: () =>
                                    setStateDialog(() => rating = starIndex),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Icon(
                                    rating >= starIndex
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 40,
                                    color: rating >= starIndex
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            starLabels[rating - 1],
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nhận xét
                    Text(
                      'Nhận xét',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      maxLength: 500,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Hãy chia sẻ trải nghiệm của bạn về món ăn (tối đa 500 ký tự)',
                        hintStyle: GoogleFonts.beVietnamPro(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        counterText: '$charCount/500',
                        counterStyle: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: charCount > 450 ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chính sách
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.policy_outlined,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Chính sách đánh giá',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...[
                            '• Chỉ đánh giá sản phẩm bạn đã mua',
                            '• Không sử dụng ngôn ngữ thô tục, xAi phạm',
                            '• Mỗi đơn hàng chỉ được đánh giá 1 lần',
                            '• Đánh giá giả mạo sẽ bị xóa và khóa tài khoản',
                          ].map(
                            (t) => Text(
                              t,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Hủy',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final comment = textController.text.trim();
                    if (comment.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập nhận xét')),
                      );
                      return;
                    }
                    final repo = context.read<UserRepository>();
                    final user = await repo.getCurrentUser();
                    await reviewRef.set({
                      'itemId': itemId,
                      'userId': uid,
                      'userName': user?.displayName ?? 'Người dùng',
                      'userPhoto': user?.photoUrl,
                      'rating': rating,
                      'comment': comment,
                      'createdAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Cảm ơn bạn đã đánh giá!',
                          style: GoogleFonts.beVietnamPro(),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Gửi đánh giá'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final ownerId = (item['ownerId'] ?? '').toString();
    final isOwner = currentUid != null && currentUid == ownerId;
    final itemId = (item['id'] ?? '').toString();

    return _ReviewSectionWidget(
      itemId: itemId,
      isOwner: isOwner,
      brandOrange: brandOrange,
      auth: _auth,
      firestore: _firestore,
    );
  }

  Widget _buildRelatedProducts(BuildContext context) {
    final itemId = (item['id'] ?? '').toString();
    final category = (item['category'] ?? '').toString();
    if (category.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _firestore
          .collection('business_food_services')
          .where('category', isEqualTo: category)
          .limit(10)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs
            .where((doc) => doc.id != itemId)
            .toList();
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Có thể bạn cũng thích',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  data['id'] = docs[index].id;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _FoodDetailPage(
                            item: data,
                            brandOrange: brandOrange,
                            brandGreen: brandGreen,
                            pageBg: pageBg,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: _buildImage(
                                data['image'] as String? ?? '',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] as String? ?? '',
                                  style: GoogleFonts.beVietnamPro(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCurrency(
                                    (data['price'] as num?)?.toDouble() ?? 0,
                                  ),
                                  style: GoogleFonts.beVietnamPro(
                                    fontWeight: FontWeight.w700,
                                    color: brandOrange,
                                    fontSize: 13,
                                  ),
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
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final ownerId = (item['ownerId'] ?? '').toString();
    final currentUid = _auth.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == ownerId;

    if (isOwner || ownerId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        final profileData = snapshot.data?.data() ?? {};
        final businessProfile =
            (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
        final isOpen = businessProfile['isOpen'] as bool? ?? true;

        if (!isOpen) {
          return SafeArea(
            child: Container(
              height: 55,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: Text(
                'Cửa hàng hiện đang tạm đóng',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          final doc = await FirebaseFirestore.instance
                              .collection('user_profiles')
                              .doc(ownerId)
                              .get();
                          if (!context.mounted) return;
                          final userDoc = await context
                              .read<UserRepository>()
                              .getUserById(ownerId);
                          if (!context.mounted) return;
                          Navigator.pop(context); // pop loading

                          final profileData = doc.data() ?? {};
                          final businessProfile =
                              profileData['businessProfile']
                                  as Map<String, dynamic>? ??
                              {};
                          final media =
                              businessProfile['media']
                                  as Map<String, dynamic>? ??
                              {};

                          final storeName = (businessProfile['name'] as String?)
                              ?.trim();
                          final displayName =
                              (storeName != null && storeName.isNotEmpty)
                              ? storeName
                              : (userDoc?.displayName.isNotEmpty == true
                                    ? userDoc!.displayName
                                    : 'Cửa hàng');
                          final avatarPath = media['avatar'] as String?;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                user: {
                                  'id': ownerId,
                                  'name': displayName,
                                  'photoUrl': avatarPath ?? userDoc?.photoUrl,
                                  'isBusinessChat': true,
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: Colors.black87,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chat ngay',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: double.infinity,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  flex: 1,
                  child: Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () => _addToCart(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_shopping_cart,
                            size: 20,
                            color: Colors.black87,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Thêm vào Giỏ hàng',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: const Color(0xFFD0011B),
                    child: InkWell(
                      onTap: () {
                        _addToCart(context, navigate: true);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Mua với voucher',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            _formatCurrency(item['price'] as double),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: _buildBottomBar(context),
      appBar: AppBar(
        backgroundColor: brandOrange,
        elevation: 0,
        title: Text(
          'Chi tiết món',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _FoodSearchPage(
                    brandOrange: brandOrange,
                    brandGreen: brandGreen,
                    pageBg: pageBg,
                    cardBg: Colors.white,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const _FoodCartPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: () {
                final extra = item['extra'] as Map<String, dynamic>? ?? {};
                final images = extra['images'] is List
                    ? (extra['images'] as List)
                          .map((e) => e.toString())
                          .toList()
                    : [item['image'] as String? ?? ''];
                if (images.isEmpty || images.first.isEmpty) {
                  return _buildImage(item['image'] as String? ?? '');
                }
                return ImageCarousel(images: images);
              }(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item['name'] as String,
            style: GoogleFonts.beVietnamPro(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(item['region'] as String, brandGreen),
              _buildTag(item['category'] as String, brandOrange),
            ],
          ),
          const SizedBox(height: 12),
          _buildSellerCard(context),
          const SizedBox(height: 16),
          if ((item['specialty']?.toString() ?? '').isNotEmpty &&
              item['specialty'].toString() != '(Không chọn)') ...[
            Text(
              'Món nổi bật',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final sp = item['specialty'].toString();
                final owner = item['ownerId'].toString();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final snap = await FirebaseFirestore.instance
                      .collection('business_food_services')
                      .where('ownerId', isEqualTo: owner)
                      .where('name', isEqualTo: sp)
                      .limit(1)
                      .get();
                  if (!context.mounted) return;
                  Navigator.pop(context); // pop loading
                  if (snap.docs.isNotEmpty) {
                    final data = snap.docs.first.data();
                    data['id'] = snap.docs.first.id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _FoodDetailPage(
                          item: data,
                          brandOrange: brandOrange,
                          brandGreen: brandGreen,
                          pageBg: pageBg,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không tìm thấy món ăn này'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(
                item['specialty'].toString(),
                style: GoogleFonts.beVietnamPro(
                  color: brandOrange,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Mô tả',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            item['description'] as String,
            style: GoogleFonts.beVietnamPro(),
          ),
          const SizedBox(height: 12),
          Text(
            'Giá tham khảo: ${_formatCurrency(item['price'] as double)}',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 12),
          if ((item['openingHours']?.toString() ?? '').isNotEmpty)
            Text(
              'Giờ mở cửa: ${item['openingHours']}',
              style: GoogleFonts.beVietnamPro(),
            ),
          const SizedBox(height: 8),
          Text(
            'Địa chỉ: ${item['address']}',
            style: GoogleFonts.beVietnamPro(),
          ),
          const SizedBox(height: 6),
          Text('Liên hệ: ${item['phone']}', style: GoogleFonts.beVietnamPro()),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          // Đánh giá ở cuối trang
          _buildReviewSection(context),
          const SizedBox(height: 12),
          const Divider(),
          _buildRelatedProducts(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FoodCartPage extends StatelessWidget {
  const _FoodCartPage();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  Future<void> _checkout(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (docs.isEmpty) return;

    final batch = _firestore.batch();
    final ordersRef = _firestore.collection('menu_orders');
    for (final doc in docs) {
      final data = doc.data();
      final orderRef = ordersRef.doc();
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;

      batch.set(orderRef, {
        'userId': uid,
        'ownerId': data['ownerId'],
        'storeName': 'Gian hàng ẩm thực',
        'items': [
          {
            'name': data['name'],
            'image': data['image'],
            'price': price,
            'quantity': quantity,
          },
        ],
        'totalPrice': price * quantity,
        'status': 'Chờ xác nhận',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.delete(doc.reference);
    }

    await batch.commit();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo đơn và làm trống giỏ hàng.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng')),
        body: const Center(child: Text('Vui lòng đăng nhập.')),
      );
    }

    final stream = _firestore
        .collection('food_carts')
        .doc(uid)
        .collection('items')
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Giỏ hàng trống.'));
          }

          double total = 0;
          for (final doc in docs) {
            final data = doc.data();
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            final qty = (data['quantity'] as num?)?.toInt() ?? 1;
            total += price * qty;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final qty = (data['quantity'] as num?)?.toInt() ?? 1;
                    final price = (data['price'] as num?)?.toDouble() ?? 0;
                    return ListTile(
                      leading:
                          data['image'] != null &&
                              (data['image'] as String).isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['image'] as String,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.restaurant),
                      title: Text((data['name'] ?? '').toString()),
                      subtitle: Text('x$qty • ${_formatCurrency(price)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => docs[index].reference.delete(),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(),
                  itemCount: docs.length,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE6E6E6))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tổng: ${_formatCurrency(total)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _checkout(context, docs),
                      child: const Text('Đặt món'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmthucvungmienPageState extends State<AmthucvungmienPage> {
  static const Color _brandOrange = Color(0xFFF45A2A);
  static const Color _brandGreen = Color(0xFF1EAD7A);
  static const Color _pageBg = Color(0xFFFFF7F2);
  static const Color _cardBg = Color(0xFFFFFFFF);

  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  StreamSubscription<List<Map<String, dynamic>>>? _itemSub;
  List<Map<String, dynamic>> _filtered = [];

  String? _filterRegion;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BusinessOnboardingHelper.ensureBusinessSetup(context);
    });
    _loadItems();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _itemSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadItems() {
    _itemSub = FirebaseBusinessService()
        .streamServices(collectionName: 'business_food_services')
        .listen((services) {
          final list = services.map((service) {
            final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
            return {
              'id': service['id']?.toString() ?? '',
              'name': (service['name'] ?? '').toString(),
              'price': (service['price'] as num?)?.toDouble() ?? 0.0,
              'originalPrice':
                  (extra['originalPrice'] as num?)?.toDouble() ?? 0.0,
              'discountPercent':
                  (extra['discountPercent'] as num?)?.toInt() ?? 0,
              'description': (service['description'] ?? '').toString(),
              'address': (service['address'] ?? '').toString(),
              'phone': (service['phone'] ?? '').toString(),
              'ownerId': (service['ownerId'] ?? '').toString(),
              'region': (extra['region'] ?? 'Khác').toString(),
              'category': (extra['category'] ?? 'Khác').toString(),
              'specialty': (extra['specialty'] ?? '').toString(),
              'stockQuantity':
                  int.tryParse((extra['stockQuantity'] ?? '').toString()) ?? -1,
              'image': (extra['imageUrl'] ?? '').toString(),
            };
          }).toList();
          if (mounted) {
            setState(() {
              _items
                ..clear()
                ..addAll(list);
              _filtered = List.from(_items);
            });
          }
        });
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _items.where((it) {
        final matchesQ =
            q.isEmpty || it['name'].toString().toLowerCase().contains(q);
        final matchesRegion =
            _filterRegion == null || it['region'] == _filterRegion;
        final matchesCategory =
            _filterCategory == null || it['category'] == _filterCategory;
        return matchesQ && matchesRegion && matchesCategory;
      }).toList();
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? selectedRegion = _filterRegion;
        String? selectedCategory = _filterCategory;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lọc nhanh',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vùng miền',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          'Bắc',
                          'Trung',
                          'Nam',
                          'Tây Bắc',
                          'Tây Nguyên',
                          'Miền Tây',
                          'Khác',
                        ].map((c) {
                          final selected = selectedRegion == c;
                          return ChoiceChip(
                            label: Text(c),
                            selected: selected,
                            selectedColor: _brandOrange.withOpacity(0.15),
                            labelStyle: GoogleFonts.beVietnamPro(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? _brandOrange
                                  : Colors.grey.shade800,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? _brandOrange
                                  : Colors.grey.shade300,
                            ),
                            onSelected: (v) => setStateSheet(
                              () => selectedRegion = v ? c : null,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loại món',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          'Đặc sản',
                          'Món chính',
                          'Ăn vặt',
                          'Lẩu',
                          'Hải sản',
                          'Chay',
                          'Khác',
                        ].map((c) {
                          final selected = selectedCategory == c;
                          return ChoiceChip(
                            label: Text(c),
                            selected: selected,
                            selectedColor: _brandGreen.withOpacity(0.12),
                            labelStyle: GoogleFonts.beVietnamPro(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? _brandGreen
                                  : Colors.grey.shade800,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? _brandGreen
                                  : Colors.grey.shade300,
                            ),
                            onSelected: (v) => setStateSheet(
                              () => selectedCategory = v ? c : null,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Hủy', style: GoogleFonts.beVietnamPro()),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _filterRegion = selectedRegion;
                          _filterCategory = selectedCategory;
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Áp dụng',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  int _activeFilterCount() {
    int count = 0;
    if (_filterRegion != null) count++;
    if (_filterCategory != null) count++;
    return count;
  }

  Widget _buildTag(String text, {Color? color, Color? bg}) {
    final chipColor = color ?? _brandOrange;
    final chipBg = bg ?? chipColor.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, size: 32, color: Colors.grey),
      );
    }
    final isNetwork =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('data:image');
    return Image(
      image: isNetwork
          ? (getImageProvider(imageUrl) ?? AssetImage(imageUrl))
                as ImageProvider
          : AssetImage(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FoodDetailPage(
          item: item,
          brandOrange: _brandOrange,
          brandGreen: _brandGreen,
          pageBg: _pageBg,
        ),
      ),
    );
  }

  void _openCollectionsPage(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CollectionsPage(
          items: items,
          brandOrange: _brandOrange,
          brandGreen: _brandGreen,
          pageBg: _pageBg,
        ),
      ),
    );
  }

  void _openFlashSalePage(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FoodListPage(
          title: 'Flash sale',
          items: items,
          brandOrange: _brandOrange,
          brandGreen: _brandGreen,
          pageBg: _pageBg,
          cardBg: _cardBg,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE6D9), Color(0xFFFFF7F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ăn gì cũng có',
            style: GoogleFonts.beVietnamPro(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF27221F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Đặc sản khắp vùng miền • Giao nhanh • Giá rõ ràng',
            style: GoogleFonts.beVietnamPro(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _FoodSearchPage(
              brandOrange: _brandOrange,
              brandGreen: _brandGreen,
              pageBg: _pageBg,
              cardBg: _cardBg,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFFFB5B2A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Món ngon ấm bụng giảm tới 40.000đ',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB9A1),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2B2522),
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                children: [
                  Text(
                    actionLabel,
                    style: GoogleFonts.beVietnamPro(
                      color: _brandOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _brandOrange,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final banners = items.take(5).toList();
    return SizedBox(
      height: 164,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final item = banners[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: DimIfClosed(
              ownerId: (item['ownerId'] ?? '').toString(),
              child: InkWell(
                onTap: () => _openDetail(item),
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(item['image'] as String),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xCCF3582A), Color(0x14F3582A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRÙM DEAL NGON',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item['name'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(item['price'] as double),
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionStrip(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final Map<String, Map<String, dynamic>> collections = {};
    for (final item in items) {
      final category = item['category'] as String;
      if (!collections.containsKey(category)) {
        collections[category] = item;
      }
    }
    final entries = collections.entries.take(8).toList();
    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return DimIfClosed(
            ownerId: (entry.value['ownerId'] ?? '').toString(),
            child: InkWell(
              onTap: () {
                _openDetail(entry.value);
              },
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: SizedBox(
                        height: 88,
                        width: double.infinity,
                        child: _buildImage(entry.value['image'] as String),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        entry.key,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: entries.length,
      ),
    );
  }

  Widget _buildFlashSale(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final deals = items.take(8).toList();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = deals[index];
          return DimIfClosed(
            ownerId: (item['ownerId'] ?? '').toString(),
            child: InkWell(
              onTap: () => _openDetail(item),
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: SizedBox(
                            height: 110,
                            width: double.infinity,
                            child: _buildImage(item['image'] as String),
                          ),
                        ),
                        if ((item['discountPercent'] as int) > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _brandOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${item['discountPercent']}%',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatCurrency(item['price'] as double),
                            style: GoogleFonts.beVietnamPro(
                              color: _brandOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((item['originalPrice'] as double) > 0)
                            Text(
                              _formatCurrency(item['originalPrice'] as double),
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: deals.length,
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = <Map<String, String>>[
      {'label': 'Tất cả', 'type': 'all'},
      {'label': 'Đặc sản', 'type': 'category'},
      {'label': 'Ăn vặt', 'type': 'category'},
      {'label': 'Lẩu', 'type': 'category'},
      {'label': 'Bắc', 'type': 'region'},
      {'label': 'Trung', 'type': 'region'},
      {'label': 'Nam', 'type': 'region'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = filters[index];
          final label = item['label'] ?? '';
          final type = item['type'] ?? '';
          final isSelected = type == 'all'
              ? _filterRegion == null && _filterCategory == null
              : type == 'region'
              ? _filterRegion == label
              : _filterCategory == label;
          final color = type == 'region' ? _brandGreen : _brandOrange;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: color.withOpacity(0.16),
            labelStyle: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Colors.grey.shade800,
            ),
            side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
            onSelected: (v) {
              setState(() {
                if (type == 'all') {
                  _filterRegion = null;
                  _filterCategory = null;
                } else if (type == 'region') {
                  _filterRegion = v ? label : null;
                } else {
                  _filterCategory = v ? label : null;
                }
              });
              _applyFilters();
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final ownerId = (item['ownerId'] ?? '').toString();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        final profileData = snapshot.data?.data() ?? {};
        final businessProfile =
            (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
        final isOpen = businessProfile['isOpen'] as bool? ?? true;

        return Opacity(
          opacity: isOpen ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetail(item),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: 118,
                      height: 118,
                      child: _buildImage(item['image'] as String),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildTag(
                                item['region'] as String,
                                color: _brandGreen,
                                bg: _brandGreen.withOpacity(0.12),
                              ),
                              _buildTag(
                                item['category'] as String,
                                color: _brandOrange,
                                bg: _brandOrange.withOpacity(0.12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['description'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _brandOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _formatCurrency(item['price'] as double),
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if ((item['openingHours']?.toString() ?? '')
                                  .isNotEmpty)
                                Text(
                                  item['openingHours'].toString(),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filtered.isNotEmpty ? _filtered : _items;
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _brandOrange,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildTopSearchBar(),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const _FoodCartPage()),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: _brandOrange,
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildIndicator(),
            ),
          ),
          if (_searchController.text.isEmpty) ...[
            SliverToBoxAdapter(child: _buildHeroBanner(visibleItems)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Bộ sưu tập',
                actionLabel: 'Xem thêm',
                onAction: () => _openCollectionsPage(visibleItems),
              ),
            ),
            SliverToBoxAdapter(child: _buildCollectionStrip(visibleItems)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Flash sale',
                actionLabel: 'Xem thêm',
                onAction: () => _openFlashSalePage(visibleItems),
              ),
            ),
            SliverToBoxAdapter(child: _buildFlashSale(visibleItems)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: Row(
                  children: [
                    Text(
                      'Gợi ý hôm nay',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Kết quả tìm kiếm',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _openFilterSheet,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_list,
                            size: 20,
                            color: _brandOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lọc',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w600,
                              color: _brandOrange,
                            ),
                          ),
                          if (_activeFilterCount() > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildTag(
                                '${_activeFilterCount()}',
                                color: _brandGreen,
                                bg: _brandGreen.withOpacity(0.14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (visibleItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _brandOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.ramen_dining,
                        color: _brandOrange,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có dữ liệu',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thử thay đổi bộ lọc hoặc tìm món khác',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList.separated(
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return _buildItemCard(item);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: visibleItems.length,
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _FoodSearchPage extends StatefulWidget {
  final Color brandOrange;
  final Color brandGreen;
  final Color pageBg;
  final Color cardBg;

  const _FoodSearchPage({
    required this.brandOrange,
    required this.brandGreen,
    required this.pageBg,
    required this.cardBg,
  });

  @override
  State<_FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<_FoodSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _history = [];
  StreamSubscription? _sub;
  bool _hasSubmitted = false;

  String? _filterRegion;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
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

  @override
  void dispose() {
    _searchController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _history = prefs.getStringList('food_search_history') ?? [];
      });
    }
  }

  Future<void> _saveHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('food_search_history') ?? [];
    history.remove(q);
    history.insert(0, q);
    if (history.length > 10) history = history.sublist(0, 10);

    await prefs.setStringList('food_search_history', history);
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('food_search_history');
    if (mounted) {
      setState(() {
        _history = [];
      });
    }
  }

  Future<void> _removeHistoryItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('food_search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('food_search_history', history);
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  void _loadItems() {
    _sub = FirebaseBusinessService()
        .streamServices(collectionName: 'business_food_services')
        .listen((services) {
          final list = services.map((service) {
            final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
            return {
              'id': service['id']?.toString() ?? '',
              'name': (service['name'] ?? '').toString(),
              'price': (service['price'] as num?)?.toDouble() ?? 0.0,
              'originalPrice':
                  (extra['originalPrice'] as num?)?.toDouble() ?? 0.0,
              'discountPercent':
                  (extra['discountPercent'] as num?)?.toInt() ?? 0,
              'description': (service['description'] ?? '').toString(),
              'address': (service['address'] ?? '').toString(),
              'phone': (service['phone'] ?? '').toString(),
              'ownerId': (service['ownerId'] ?? '').toString(),
              'businessName': (extra['businessName'] ?? '').toString(),
              'region': (extra['region'] ?? 'Khác').toString(),
              'category': (extra['category'] ?? 'Khác').toString(),
              'specialty': (extra['specialty'] ?? '').toString(),
              'openingHours': (extra['openingHours'] ?? '').toString(),
              'image': (extra['imageUrl'] ?? '').toString(),
            };
          }).toList();
          if (mounted) {
            setState(() {
              _allItems = list;
              _applyFilters();
            });
          }
        });
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allItems.where((it) {
        final name = it['name'].toString().toLowerCase();
        final address = it['address'].toString().toLowerCase();
        final bName = (it['businessName']?.toString() ?? '').toLowerCase();

        final matchesQ =
            q.isEmpty ||
            name.contains(q) ||
            address.contains(q) ||
            bName.contains(q);

        final matchesRegion =
            _filterRegion == null || it['region'] == _filterRegion;
        final matchesCategory =
            _filterCategory == null || it['category'] == _filterCategory;
        return matchesQ && matchesRegion && matchesCategory;
      }).toList();
    });
  }

  int _activeFilterCount() {
    int c = 0;
    if (_filterRegion != null) c++;
    if (_filterCategory != null) c++;
    return c;
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? selectedRegion = _filterRegion;
        String? selectedCategory = _filterCategory;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lọc món ăn',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vùng miền',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          'Bắc',
                          'Trung',
                          'Nam',
                          'Tây Bắc',
                          'Tây Nguyên',
                          'Miền Tây',
                          'Khác',
                        ].map((c) {
                          final selected = selectedRegion == c;
                          return ChoiceChip(
                            label: Text(c),
                            selected: selected,
                            selectedColor: widget.brandOrange.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: GoogleFonts.beVietnamPro(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? widget.brandOrange
                                  : Colors.grey.shade800,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? widget.brandOrange
                                  : Colors.grey.shade300,
                            ),
                            onSelected: (v) => setStateSheet(
                              () => selectedRegion = v ? c : null,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Danh mục',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: ['Đặc sản', 'Ăn vặt', 'Lẩu', 'Khác'].map((c) {
                      final selected = selectedCategory == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        selectedColor: widget.brandGreen.withValues(
                          alpha: 0.15,
                        ),
                        labelStyle: GoogleFonts.beVietnamPro(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? widget.brandGreen
                              : Colors.grey.shade800,
                        ),
                        side: BorderSide(
                          color: selected
                              ? widget.brandGreen
                              : Colors.grey.shade300,
                        ),
                        onSelected: (v) => setStateSheet(
                          () => selectedCategory = v ? c : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setStateSheet(() {
                              selectedRegion = null;
                              selectedCategory = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade800,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Thiết lập lại',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterRegion = selectedRegion;
                              _filterCategory = selectedCategory;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.brandOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Áp dụng',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTag(String label, {required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.pageBg,
      appBar: AppBar(
        backgroundColor: widget.brandOrange,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFFFB5B2A)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  autofocus: true,
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) {
                    _submitSearch(val);
                  },
                  style: GoogleFonts.beVietnamPro(),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm món ăn...',
                    hintStyle: GoogleFonts.beVietnamPro(
                      color: Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                  },
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const _FoodCartPage()),
              );
            },
          ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? _buildIdleState()
          : (!_hasSubmitted
                ? _buildKeywordSuggestions()
                : _buildSearchResults()),
    );
  }

  Widget _buildKeywordSuggestions() {
    final keywordSuggestions = _filtered
        .map((e) => e['name'].toString())
        .toSet()
        .take(10)
        .toList();

    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.search, color: widget.brandOrange),
          title: RichText(
            text: TextSpan(
              text: 'Tìm ',
              style: GoogleFonts.beVietnamPro(color: Colors.black),
              children: [
                TextSpan(
                  text: '"${_searchController.text}"',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                    color: widget.brandOrange,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            _submitSearch(_searchController.text);
          },
        ),
        const Divider(height: 1),
        ...keywordSuggestions.map((suggestion) {
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.search, color: Colors.grey),
                title: Text(
                  suggestion,
                  style: GoogleFonts.beVietnamPro(color: Colors.grey.shade800),
                ),
                onTap: () {
                  _searchController.text = suggestion;
                  _submitSearch(suggestion);
                },
              ),
              const Divider(height: 1),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildIdleState() {
    final suggestions = _allItems.take(6).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_history.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch sử tìm kiếm',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  InkWell(
                    onTap: _clearHistory,
                    child: Text(
                      'Xóa',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _history.map((h) {
                  return InkWell(
                    onTap: () {
                      _searchController.text = h;
                      _submitSearch(h);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 8,
                        top: 6,
                        bottom: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            h,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              _removeHistoryItem(h);
                            },
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Gợi ý cho bạn',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          if (suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return _FoodSearchItemCard(
                  item: item,
                  brandOrange: widget.brandOrange,
                  brandGreen: widget.brandGreen,
                  pageBg: widget.pageBg,
                  cardBg: widget.cardBg,
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: suggestions.length,
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Kết quả tìm kiếm',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _openFilterSheet,
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: widget.brandOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lọc',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w600,
                        color: widget.brandOrange,
                      ),
                    ),
                    if (_activeFilterCount() > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildTag(
                          '${_activeFilterCount()}',
                          color: widget.brandGreen,
                          bg: widget.brandGreen.withValues(alpha: 0.14),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy món ăn nào',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thử tìm với từ khóa khác xem sao nhé!',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (_allItems.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Đề xuất cho bạn',
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final suggestionList = _allItems.take(5).toList();
                            if (index >= suggestionList.length)
                              return const SizedBox();
                            final item = suggestionList[index];
                            return _FoodSearchItemCard(
                              item: item,
                              brandOrange: widget.brandOrange,
                              brandGreen: widget.brandGreen,
                              pageBg: widget.pageBg,
                              cardBg: widget.cardBg,
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount: _allItems.length > 5
                              ? 5
                              : _allItems.length,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    return _FoodSearchItemCard(
                      item: item,
                      brandOrange: widget.brandOrange,
                      brandGreen: widget.brandGreen,
                      pageBg: widget.pageBg,
                      cardBg: widget.cardBg,
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _filtered.length,
                ),
        ),
      ],
    );
  }
}

class _FoodSearchItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color brandOrange;
  final Color brandGreen;
  final Color pageBg;
  final Color cardBg;

  const _FoodSearchItemCard({
    required this.item,
    required this.brandOrange,
    required this.brandGreen,
    required this.pageBg,
    required this.cardBg,
  });

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, size: 32, color: Colors.grey),
      );
    }
    final isNetwork =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('data:image');
    return Image(
      image: isNetwork
          ? (getImageProvider(imageUrl) ?? AssetImage(imageUrl))
                as ImageProvider
          : AssetImage(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _FoodDetailPage(
                item: item,
                brandOrange: brandOrange,
                brandGreen: brandGreen,
                pageBg: pageBg,
              ),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: _buildImage(item['image'] as String),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatCurrency(item['price'] as double),
                      style: GoogleFonts.beVietnamPro(
                        color: brandOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSectionWidget extends StatefulWidget {
  final String itemId;
  final bool isOwner;
  final Color brandOrange;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const _ReviewSectionWidget({
    Key? key,
    required this.itemId,
    required this.isOwner,
    required this.brandOrange,
    required this.auth,
    required this.firestore,
  }) : super(key: key);

  @override
  State<_ReviewSectionWidget> createState() => _ReviewSectionWidgetState();
}

class _ReviewSectionWidgetState extends State<_ReviewSectionWidget> {
  late Future<bool> _canReviewFuture;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _reviewStream;

  @override
  void initState() {
    super.initState();
    _canReviewFuture = _checkCanReview();
    _reviewStream = _createReviewStream();
  }

  Future<bool> _checkCanReview() async {
    final uid = widget.auth.currentUser?.uid;
    if (uid == null) return false;
    if (widget.itemId.isEmpty) return false;
    final snap = await widget.firestore
        .collection('food_orders')
        .where('userId', isEqualTo: uid)
        .where('itemId', isEqualTo: widget.itemId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _createReviewStream() {
    if (widget.itemId.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return widget.firestore
        .collection('food_reviews')
        .where('itemId', isEqualTo: widget.itemId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget _buildRatingStars(double rating, {double size = 14}) {
    final stars = List.generate(5, (index) {
      final filled = rating >= index + 1;
      final half = rating > index && rating < index + 1;
      return Icon(
        half ? Icons.star_half : Icons.star,
        size: size,
        color: filled || half ? Colors.amber : Colors.grey.shade300,
      );
    });
    return Row(children: stars);
  }

  Future<void> _openReviewDialog(BuildContext context, bool canReview) async {
    if (!canReview) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Chưa thể đánh giá',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Bạn cần mua và sử dụng sản phẩm này trước khi có thể viết đánh giá. Điều này giúp đảm bảo tính xác thực của các nhận xét.',
            style: GoogleFonts.beVietnamPro(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Đóng',
                style: GoogleFonts.beVietnamPro(color: widget.brandOrange),
              ),
            ),
          ],
        ),
      );
      return;
    }

    double rating = 5;
    final commentCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Viết đánh giá',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Bạn cảm thấy sản phẩm này thế nào?',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              onPressed: () {
                                setState(() => rating = index + 1.0);
                              },
                              icon: Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                size: 40,
                                color: Colors.amber,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chia sẻ trải nghiệm của bạn',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Món ăn có ngon không? Phục vụ thế nào...',
                        hintStyle: GoogleFonts.beVietnamPro(
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.brandOrange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final uid = widget.auth.currentUser?.uid;
                        if (uid == null) return;
                        final comment = commentCtrl.text.trim();
                        final reviewId = '${widget.itemId}_$uid';
                        final reviewRef = widget.firestore
                            .collection('food_reviews')
                            .doc(reviewId);

                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập nhận xét'),
                            ),
                          );
                          return;
                        }
                        final repo = context.read<UserRepository>();
                        final user = await repo.getCurrentUser();
                        await reviewRef.set({
                          'itemId': widget.itemId,
                          'userId': uid,
                          'userName': user?.displayName ?? 'Người dùng',
                          'userPhoto': user?.photoUrl,
                          'rating': rating,
                          'comment': comment,
                          'createdAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Cảm ơn bạn đã đánh giá!',
                              style: GoogleFonts.beVietnamPro(),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.brandOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Gửi đánh giá'),
                    ),
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
    return FutureBuilder<bool>(
      future: _canReviewFuture,
      builder: (context, canReviewSnap) {
        final canReview = canReviewSnap.data ?? false;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _reviewStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            double avg = 0;
            if (docs.isNotEmpty) {
              final total = docs.fold<double>(
                0,
                (s, doc) => s + ((doc.data()['rating'] as int?) ?? 0),
              );
              avg = total / docs.length;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Đánh giá & Nhận xét',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (!widget.isOwner) ...[
                      if (canReview)
                        TextButton.icon(
                          onPressed: () =>
                              _openReviewDialog(context, canReview),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(
                            'Viết đánh giá',
                            style: GoogleFonts.beVietnamPro(),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: widget.brandOrange,
                          ),
                        )
                      else
                        Tooltip(
                          message: 'Mua món để viết đánh giá',
                          child: TextButton.icon(
                            onPressed: () =>
                                _openReviewDialog(context, canReview),
                            icon: Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            label: Text(
                              'Viết đánh giá',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade400,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: widget.brandOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRatingStars(avg, size: 18),
                          const SizedBox(height: 4),
                          Text(
                            '${docs.length} đánh giá',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 40,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          if (widget.isOwner) ...[
                            Text(
                              'Sản phẩm của bạn chưa có đánh giá nào.',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              'Những đánh giá từ khách hàng sẽ xuất hiện tại đây!',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Chưa có đánh giá nào.',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              'Hãy là người đầu tiên đánh giá!',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ...docs.map((doc) {
                    final data = doc.data();
                    final name = (data['userName'] ?? 'Người dùng').toString();
                    final comment = (data['comment'] ?? '').toString();
                    final r = (data['rating'] as int?) ?? 0;
                    final ts = data['createdAt'] as Timestamp?;
                    final dateStr = ts != null
                        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                        : '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: data['userPhoto'] != null
                                ? getImageProvider(data['userPhoto'] as String)
                                : null,
                            child: data['userPhoto'] == null
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.beVietnamPro(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (dateStr.isNotEmpty)
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.beVietnamPro(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                _buildRatingStars(r.toDouble(), size: 13),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    comment,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Đã mua hàng',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        color: Colors.green.shade600,
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
                  }),
              ],
            );
          },
        );
      },
    );
  }
}
