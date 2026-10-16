import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/business/business_profile_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'vehicle_booking_page.dart';

class VehicleDetailPage extends StatefulWidget {
  final Map<String, dynamic> rawService;
  final String mappedName;
  final String mappedPrice;
  final String mappedNote;
  final String mappedOwnerPhone;

  const VehicleDetailPage({
    super.key,
    required this.rawService,
    required this.mappedName,
    required this.mappedPrice,
    required this.mappedNote,
    required this.mappedOwnerPhone,
  });

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  void _goToBookingPage() {
    final extraData =
        (widget.rawService['extra'] as Map<String, dynamic>?) ?? {};
    final extraImageUrl = extraData['imageUrl'] as String?;
    final extraImages = (extraData['images'] as List?)?.cast<String>() ?? [];
    List<String> images = (widget.rawService['images'] as List?)?.cast<String>() ?? [];
    if (images.isEmpty) {
      images = extraImages;
    }
    final image = images.isNotEmpty ? images.first : (extraImageUrl ?? '');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleBookingPage(
          rawService: widget.rawService,
          mappedName: widget.mappedName,
          mappedPrice: widget.mappedPrice,
          imageUrl: image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final extraData =
        (widget.rawService['extra'] as Map<String, dynamic>?) ?? {};
    final extraImageUrl = extraData['imageUrl'] as String?;
    final extraImages = (extraData['images'] as List?)?.cast<String>() ?? [];
    List<String> images = (widget.rawService['images'] as List?)?.cast<String>() ?? [];
    if (images.isEmpty) {
      images = extraImages;
    }
    final image = images.isNotEmpty ? images.first : (extraImageUrl ?? '');
    final ownerId = widget.rawService['ownerId']?.toString() ?? '';
    final isOwner = FirebaseAuth.instance.currentUser?.uid == ownerId;

    final quantity = (widget.rawService['quantity'] as num?)?.toInt() ?? (extraData['quantity'] as num?)?.toInt() ?? 5;
    final soldCount = (widget.rawService['soldCount'] as num?)?.toInt() ?? (extraData['soldCount'] as num?)?.toInt() ?? 0;
    final rating = (widget.rawService['rating'] as num?)?.toDouble() ?? (extraData['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewsCount = (widget.rawService['reviewsCount'] as num?)?.toInt() ?? (extraData['reviewsCount'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phương tiện'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty || extraImageUrl != null)
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageCarousel(
                      images: images.isNotEmpty ? images : [extraImageUrl!],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Số lượng xe trống: $quantity',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mappedName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mappedPrice,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (ownerId.isNotEmpty)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('user_profiles')
                      .doc(ownerId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) return const SizedBox();
                    final businessProfile =
                        data['businessProfile'] as Map<String, dynamic>? ?? {};
                    final ownerProfile =
                        data['ownerProfile'] as Map<String, dynamic>? ?? {};
                        
                    String _getValidString(List<String?> values, String defaultValue) {
                      for (final v in values) {
                        if (v != null && v.trim().isNotEmpty) return v.trim();
                      }
                      return defaultValue;
                    }

                    final storeName = _getValidString([
                      businessProfile['name'] as String?,
                      ownerProfile['name'] as String?,
                      data['fullName'] as String?,
                    ], 'Người đăng');

                    final media =
                        businessProfile['media'] as Map<String, dynamic>? ?? {};
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
                      final parts = address.split(',').map((e) => e.trim()).toList();
                      if (parts.length >= 2) {
                        displayAddress = '${parts[parts.length - 2]}, ${parts.last}';
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
                            builder: (context) => BusinessProfilePage(ownerId: ownerId),
                          ),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: ownerId.isNotEmpty 
                    ? FirebaseFirestore.instance.collection('menu_orders')
                        .where('ownerId', isEqualTo: ownerId)
                        .where('type', isEqualTo: 'vehicle_rental')
                        .snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  int realSoldCount = soldCount;
                  double realRating = rating;
                  int realReviewsCount = reviewsCount;

                  if (snapshot.hasData) {
                    int calculatedSold = 0;
                    double totalRating = 0;
                    int calculatedReviews = 0;

                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final items = data['items'] as List<dynamic>? ?? [];
                      if (items.isNotEmpty) {
                        final itemName = items[0]['name']?.toString() ?? '';
                        if (itemName.contains(widget.mappedName)) {
                          calculatedSold++;
                          if (data['rating'] != null) {
                            calculatedReviews++;
                            totalRating += (data['rating'] as num).toDouble();
                          }
                        }
                      }
                    }
                    if (calculatedSold > 0) realSoldCount = calculatedSold;
                    if (calculatedReviews > 0) {
                      realReviewsCount = calculatedReviews;
                      realRating = totalRating / calculatedReviews;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã thuê: $realSoldCount',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Liên hệ: ${widget.mappedOwnerPhone}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Mô tả:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.mappedNote),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            realRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($realReviewsCount đánh giá)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              if (!isOwner)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _goToBookingPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Đặt thuê ngay',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
