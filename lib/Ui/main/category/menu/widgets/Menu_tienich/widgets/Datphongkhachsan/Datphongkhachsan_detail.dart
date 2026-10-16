import 'package:flutter/material.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/Ui/main/category/business/business_profile_page.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';

import 'Datphongkhachsan_booking.dart';

class HotelDetailPage extends StatelessWidget {
  const HotelDetailPage({super.key, required this.hotel});

  final Map<String, dynamic> hotel;

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == (hotel['ownerId'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: Text(hotel['name'])),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image carousel
            SizedBox(
              height: 200,
              child: ImageCarousel(
                images: (hotel['images'] as List).map((e) => e.toString()).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hotel['starClass'] != null && hotel['starClass'] > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Khách sạn ${(hotel['starClass'] as double) == (hotel['starClass'] as double).toInt() ? (hotel['starClass'] as double).toInt() : hotel['starClass']} sao',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final extra = hotel['extra'] as Map<String, dynamic>? ?? {};
                      int stockCount = (hotel['stockCount'] as num?)?.toInt() ?? (extra['stockCount'] as num?)?.toInt() ?? (hotel['quantity'] as num?)?.toInt() ?? 0;
                      if (stockCount == 0 && extra['roomCount'] != null) {
                        stockCount = int.tryParse(extra['roomCount'].toString()) ?? 0;
                      }
                      final available = stockCount > 0;
                      return Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: available ? Colors.green : Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            available ? 'Số lượng còn: $stockCount' : 'Hết phòng',
                            style: TextStyle(color: available ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (hotel['ownerId'] != null && hotel['ownerId'].toString().isNotEmpty) ...[
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('user_profiles').doc(hotel['ownerId'].toString()).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox();
                        
                        final businessProfile = data['businessProfile'] as Map<String, dynamic>? ?? {};
                        final ownerProfile = data['ownerProfile'] as Map<String, dynamic>? ?? {};
                        
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

                        final media = businessProfile['media'] as Map<String, dynamic>? ?? {};
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
                            backgroundImage: avatar.isNotEmpty ? getImageProvider(avatar) : null,
                            child: avatar.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          title: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(displayAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusinessProfilePage(ownerId: hotel['ownerId'].toString()),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Đã đặt: ${(hotel['soldCount'] as num?)?.toInt() ?? 0}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ưu đãi:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (hotel['amenities'] as List? ?? []).map((amenity) {
                      return Chip(label: Text(amenity.toString()));
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(hotel['desc']),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Giá từ: ${(hotel['price'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')} ₫',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!isOwner)
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HotelBookingPage(hotel: hotel),
                            ),
                          ),
                          child: const Text('Đặt phòng'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${hotel['rating']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${hotel['reviewCount'] ?? (hotel['reviewsCount'] as num?)?.toInt() ?? 0} đánh giá)',
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
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseBusinessService().streamServices(collectionName: 'business_hotel_services'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final currentId = hotel['id']?.toString() ?? '';
                      
                      final similarItems = snapshot.data!.where((item) {
                        if (item['status'] != 'active') return false;
                        if (item['id']?.toString() == currentId) return false;
                        return item['ownerId'] == hotel['ownerId'];
                      }).take(4).toList();

                      if (similarItems.isEmpty) return const Text('Không có sản phẩm tương tự', style: TextStyle(color: Colors.grey));

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: similarItems.length,
                        itemBuilder: (context, index) {
                          final item = similarItems[index];
                          final extra = item['extra'] as Map<String, dynamic>? ?? {};
                          final imageUrl = extra['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800';
                          
                          double starClass = 0.0;
                          if (extra['starRating'] != null) {
                            final String rawStar = extra['starRating'].toString();
                            final numStr = rawStar.replaceAll(RegExp(r'[^0-9.]'), '');
                            starClass = double.tryParse(numStr) ?? 0.0;
                          }
                          double userRating = (item['rating'] as num?)?.toDouble() ?? 0.0;
                          int reviewCount = (item['reviewCount'] as num?)?.toInt() ?? (item['reviewsCount'] as num?)?.toInt() ?? 0;
                          final mappedItem = {
                            ...item,
                            'id': item['id'],
                            'ownerId': item['ownerId'],
                            'name': item['name'] ?? '',
                            'location': item['address'] ?? '',
                            'starClass': starClass,
                            'rating': userRating,
                            'reviewCount': reviewCount,
                            'price': (item['price'] as num?)?.toInt() ?? 0,
                            'desc': item['description'] ?? '',
                            'images': extra['images'] is List ? (extra['images'] as List).map((e) => e.toString()).toList() : [imageUrl],
                            'amenities': extra['amenities'] is List ? (extra['amenities'] as List).map((e) => e.toString()).toList() : ['WiFi'],
                          };

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HotelDetailPage(hotel: mappedItem),
                                ),
                              );
                            },
                            child: Card(
                              clipBehavior: Clip.hardEdge,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Image(
                                      image: (imageUrl.startsWith('http') || imageUrl.startsWith('data:image'))
                                          ? (getImageProvider(imageUrl) ?? const AssetImage('asset/images/anhdemo.jpeg'))
                                          : AssetImage(imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mappedItem['name'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${mappedItem['price']}đ',
                                          style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}
