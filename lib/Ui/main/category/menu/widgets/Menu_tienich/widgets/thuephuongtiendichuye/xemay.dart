import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'vehicle_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Xemay extends StatelessWidget {
  const Xemay({super.key});

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F2FA);
    const Color accent = Color(0xFF6B5FB5);

    return Scaffold(
      appBar: AppBar(title: const Text('Thuê xe máy'), centerTitle: true),
      backgroundColor: pageBg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          _HeaderCard(
            icon: Icons.motorcycle,
            title: 'Xe máy cho hành trình linh hoạt',
            subtitle: 'Chọn hình thức thuê phù hợp với nhu cầu',
          ),
          const SizedBox(height: 12),
          const _SectionTitle(title: 'Hình thức thuê'),
          const SizedBox(height: 8),
          _OptionCard(
            icon: Icons.key,
            title: 'Thuê xe tự lái',
            subtitle: 'Tự do lịch trình, chủ động thời gian',
            accent: accent,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const XemayTuLaiPage()));
            },
          ),
          const SizedBox(height: 10),
          _OptionCard(
            icon: Icons.person_pin_circle,
            title: 'Thuê xe có người lái',
            subtitle: 'An tâm di chuyển, có tài xế hỗ trợ',
            accent: accent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const XemayCoTaiXePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class XemayTuLaiPage extends StatefulWidget {
  const XemayTuLaiPage({super.key});

  @override
  State<XemayTuLaiPage> createState() => _XemayTuLaiPageState();
}

class _XemayTuLaiPageState extends State<XemayTuLaiPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseBusinessService().streamServices(
        collectionName: 'business_transport_services',
      ),
      builder: (context, snapshot) {
        final motos = _mapTransportServices(
          snapshot.data ?? [],
          vehicleType: 'Xe máy',
          rentalMode: 'Tự lái',
        );
        final types = _buildTypes(motos);
        return _MotoListPage(
          title: 'Xe máy tự lái',
          subtitle: 'Chọn xe phù hợp nhu cầu',
          motos: motos,
          types: types,
          searchController: _searchController,
          selectedType: _selectedType,
          onTypeChanged: (type) => setState(() => _selectedType = type),
          onSearchChanged: (_) => setState(() {}),
        );
      },
    );
  }
}

class XemayCoTaiXePage extends StatefulWidget {
  const XemayCoTaiXePage({super.key});

  @override
  State<XemayCoTaiXePage> createState() => _XemayCoTaiXePageState();
}

class _XemayCoTaiXePageState extends State<XemayCoTaiXePage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseBusinessService().streamServices(
        collectionName: 'business_transport_services',
      ),
      builder: (context, snapshot) {
        final motos = _mapTransportServices(
          snapshot.data ?? [],
          vehicleType: 'Xe máy',
          rentalMode: 'Có tài xế',
        );
        final types = _buildTypes(motos);
        return _MotoListPage(
          title: 'Xe máy có người lái',
          subtitle: 'An tâm di chuyển mọi hành trình',
          motos: motos,
          types: types,
          searchController: _searchController,
          selectedType: _selectedType,
          onTypeChanged: (type) => setState(() => _selectedType = type),
          onSearchChanged: (_) => setState(() {}),
        );
      },
    );
  }
}

class _MotoListPage extends StatelessWidget {
  const _MotoListPage({
    required this.title,
    required this.subtitle,
    required this.motos,
    required this.types,
    required this.searchController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> motos;
  final List<String> types;
  final TextEditingController searchController;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F2FA);
    const Color accent = Color(0xFF6B5FB5);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final query = searchController.text.trim().toLowerCase();
    final filtered = motos
        .where((moto) {
          if (query.isEmpty) return true;
          return moto.values.whereType<String>().any(
            (v) => v.toLowerCase().contains(query),
          );
        })
        .where((moto) {
          if (selectedType == 'Tất cả') return true;
          return moto['type'] == selectedType;
        })
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      backgroundColor: pageBg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          _HeaderCard(icon: Icons.motorcycle, title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          _SearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
            hintText: 'Tìm theo loại xe, shop, khu vực...',
          ),
          const SizedBox(height: 8),
          _FilterBar(
            types: types,
            selectedType: selectedType,
            onSelected: onTypeChanged,
          ),
          const SizedBox(height: 12),
          const _SectionTitle(title: 'Xe máy có sẵn'),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const _EmptyState(message: 'Không tìm thấy xe phù hợp'),
          ...filtered.map((moto) {
            final rawService = moto['raw'] as Map<String, dynamic>? ?? {};
            final ownerId = rawService['ownerId']?.toString() ?? '';
            final isOwner = currentUid.isNotEmpty && currentUid == ownerId;
            
            Widget cardWidget = _MotoCard(
              name: moto['name']?.toString() ?? '',
              price: moto['price']?.toString() ?? '',
              note: moto['note']?.toString() ?? '',
              owner: moto['owner']?.toString() ?? '',
              location: moto['location']?.toString() ?? '',
              accent: accent,
              imageUrl: moto['imageUrl']?.toString() ?? '',
              isOwner: isOwner,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehicleDetailPage(
                      rawService: rawService,
                      mappedName: moto['name']?.toString() ?? '',
                      mappedPrice: moto['price']?.toString() ?? '',
                      mappedNote: moto['note']?.toString() ?? '',
                      mappedOwnerPhone: moto['owner']?.toString() ?? '',
                    ),
                  ),
                );
              },
            );

            if (ownerId.isNotEmpty) {
              Widget currentCard = cardWidget;
              cardWidget = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                    child: currentCard,
                  );
                },
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: cardWidget,
            );
          }),
        ],
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển')));
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF1ECFF), Color(0xFFE8F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6B5FB5), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x1F6B5FB5)),
      ),
      elevation: 1.5,
      shadowColor: const Color(0x1F000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotoCard extends StatelessWidget {
  const _MotoCard({
    required this.name,
    required this.price,
    required this.note,
    required this.owner,
    required this.location,
    required this.accent,
    required this.onTap,
    this.imageUrl = '',
    this.isOwner = false,
  });

  final String name;
  final String price;
  final String note;
  final String owner;
  final String location;
  final Color accent;
  final VoidCallback onTap;
  final String imageUrl;
  final bool isOwner;

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

  Widget _buildFallbackIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(Icons.motorcycle, color: accent, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x1F6B5FB5)),
      ),
      elevation: 1.5,
      shadowColor: const Color(0x1F000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(
                    image: _getImageProvider(imageUrl) ?? const AssetImage('asset/images/anhdemo.jpeg') as ImageProvider,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                  ),
                )
              else
                _buildFallbackIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      owner,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isOwner) ...[
                    const SizedBox(height: 6),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x1F6B5FB5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x1F6B5FB5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6B5FB5)),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.types,
    required this.selectedType,
    required this.onSelected,
  });

  final List<String> types;
  final String selectedType;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final selected = selectedType == type;
          return FilterChip(
            label: Text(type),
            selected: selected,
            onSelected: (_) => onSelected(type),
            showCheckmark: false,
            selectedColor: const Color(0xFFE8E1FF),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0x1F6B5FB5)),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF6B5FB5) : Colors.black87,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}

List<Map<String, dynamic>> _mapTransportServices(
  List<Map<String, dynamic>> services, {
  required String vehicleType,
  String? rentalMode,
}) {
  return services
      .where((service) {
        if (service['status'] != 'active') return false;
        if (service['categoryHidden'] == true) return false;
        final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
        final type = (extra['vehicleType'] ?? '').toString();
        if (type != vehicleType) return false;
        if (rentalMode == null) return true;
        return (extra['rentalMode'] ?? '').toString() == rentalMode;
      })
      .map((service) {
        final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
        final durations =
            (service['durationOptions'] as List?)?.cast<String>() ?? [];
        final unit = durations.isNotEmpty ? durations.first : '';
        final capacity = (extra['capacity'] ?? '').toString();

        final extraImageUrl = extra['imageUrl'] as String?;
        final images = (service['images'] as List?)?.cast<String>() ?? [];
        final imageUrl = images.isNotEmpty ? images.first : (extraImageUrl ?? '');

        return <String, dynamic>{
          'raw': service,
          'name': (service['name'] ?? '').toString(),
          'price':
              '${_formatCurrency(service['price'])}${unit.isNotEmpty ? '/$unit' : ''}',
          'note': (service['description'] ?? '').toString(),
          'owner': (service['phone'] ?? '').toString(),
          'location': (service['address'] ?? '').toString(),
          'type': capacity.isNotEmpty ? capacity : vehicleType,
          'imageUrl': imageUrl,
        };
      })
      .toList();
}

List<String> _buildTypes(List<Map<String, dynamic>> items) {
  final types = <String>{'Tất cả'};
  for (final item in items) {
    final type = item['type']?.toString();
    if (type != null && type.trim().isNotEmpty) {
      types.add(type);
    }
  }
  return types.toList();
}

String _formatCurrency(dynamic value) {
  if (value == null) return '-';
  final number = value is num ? value.toInt() : int.tryParse(value.toString());
  if (number == null) return '-';
  final s = number.toString();
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return '${s.replaceAll(reg, '.')} đ';
}
