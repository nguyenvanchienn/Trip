import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'vehicle_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cacphuongtienkhac extends StatelessWidget {
  const Cacphuongtienkhac({super.key});

  ImageProvider? _getImageProvider(String url) {
    if (url.startsWith('http')) return NetworkImage(url);
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildFallbackIcon(Color accent) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(Icons.directions_car, color: accent, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF6B5FB5);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Phương tiện khác'), centerTitle: true),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseBusinessService().streamServices(
          collectionName: 'business_transport_services',
        ),
        builder: (context, snapshot) {
          final services = snapshot.data ?? [];
          final items = services.where((service) {
        if (service['status'] != 'active') return false;
        if (service['categoryHidden'] == true) return false;
            final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
            return (extra['vehicleType'] ?? '').toString() == 'Khác';
          }).toList();

          if (items.isEmpty) {
            return const Center(child: Text('Chưa có dịch vụ phù hợp'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final service = items[index];
              final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
              final durations =
                  (service['durationOptions'] as List?)?.cast<String>() ?? [];
              final unit = durations.isNotEmpty ? durations.first : '';
              final price = _formatCurrency(service['price']);
              final ownerId = service['ownerId']?.toString() ?? '';
              final isOwner =
                  currentUid.isNotEmpty && currentUid == ownerId;

              final extraImageUrl = extra['imageUrl'] as String?;
              final images = (service['images'] as List?)?.cast<String>() ?? [];
              final imageUrl = images.isNotEmpty ? images.first : (extraImageUrl ?? '');

              Widget tileWidget = ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0x1F6B5FB5)),
                ),
                leading: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(
                          image: _getImageProvider(imageUrl) ?? const AssetImage('asset/images/anhdemo.jpeg') as ImageProvider,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackIcon(accent),
                        ),
                      )
                    : _buildFallbackIcon(accent),
                title: Text((service['name'] ?? '').toString()),
                subtitle: Text((service['description'] ?? '').toString()),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      unit.isNotEmpty ? '$price/$unit' : price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    if (!isOwner) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đặt ngay',
                        style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  final durations2 =
                      (service['durationOptions'] as List?)
                              ?.cast<String>() ??
                          [];
                  final unit2 =
                      durations2.isNotEmpty ? durations2.first : '';
                  final priceStr =
                      '${_formatCurrency(service['price'])}${unit2.isNotEmpty ? '/$unit2' : ''}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailPage(
                        rawService: service,
                        mappedName:
                            (service['name'] ?? '').toString(),
                        mappedPrice: priceStr,
                        mappedNote:
                            (service['description'] ?? '').toString(),
                        mappedOwnerPhone:
                            (service['phone'] ?? '').toString(),
                      ),
                    ),
                  );
                },
              );

              if (ownerId.isNotEmpty) {
                tileWidget = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('user_profiles')
                      .doc(ownerId)
                      .snapshots(),
                  builder: (context, profileSnap) {
                    final profileData = profileSnap.data?.data() ?? {};
                    final businessProfile = (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
                    final isOpen = businessProfile['isOpen'] as bool? ?? true;
                    return Opacity(
                      opacity: isOpen ? 1.0 : 0.5,
                      child: tileWidget,
                    );
                  },
                );
              }

              return tileWidget;
            },
          );
        },
      ),
    );
  }
}

String _formatCurrency(dynamic value) {
  if (value == null) return '-';
  final number = value is num ? value.toInt() : int.tryParse(value.toString());
  if (number == null) return '-';
  final s = number.toString();
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return '${s.replaceAll(reg, '.')} đ';
}
