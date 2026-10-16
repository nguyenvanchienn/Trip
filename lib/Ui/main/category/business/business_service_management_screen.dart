import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

import 'service_create/create_transport_service_page.dart';
import 'service_create/create_flight_ticket_service_page.dart';
import 'service_create/create_ship_ticket_service_page.dart';
import 'service_create/create_train_ticket_service_page.dart';
import 'service_create/create_bus_ticket_service_page.dart';
import 'service_create/create_hotel_service_page.dart';
import 'service_create/create_guide_service_page.dart';
import 'service_create/create_photographer_service_page.dart';
import 'service_create/create_clothes_service_page.dart';
import 'service_create/create_food_service_page.dart';

/// Trang quản lý dịch vụ: hiển thị tất cả dịch vụ của owner hiện tại,
/// phân nhóm theo loại dịch vụ. Cho phép xóa dịch vụ.
class BusinessServiceManagementScreen extends StatelessWidget {
  const BusinessServiceManagementScreen({super.key});

  static const _collections = <_ServiceCategory>[
    _ServiceCategory('Thuê phương tiện', 'business_transport_services', Icons.directions_car_outlined),
    _ServiceCategory('Vé máy bay', 'business_flight_ticket_services', Icons.flight_outlined),
    _ServiceCategory('Vé tàu/phà', 'business_ship_ticket_services', Icons.directions_boat_outlined),
    _ServiceCategory('Vé tàu hỏa', 'business_train_ticket_services', Icons.train_outlined),
    _ServiceCategory('Vé xe khách', 'business_bus_ticket_services', Icons.directions_bus_outlined),
    _ServiceCategory('Phòng khách sạn', 'business_hotel_services', Icons.hotel_outlined),
    _ServiceCategory('Hướng dẫn viên', 'business_guide_services', Icons.record_voice_over_outlined),
    _ServiceCategory('Thợ chụp ảnh', 'business_photographer_services', Icons.camera_alt_outlined),
    _ServiceCategory('Thuê quần áo', 'business_clothes_services', Icons.checkroom_outlined),
    _ServiceCategory('Ẩm thực', 'business_food_services', Icons.restaurant_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _collections.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý dịch vụ'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _collections
                .map((c) => Tab(
                      icon: Icon(c.icon, size: 18),
                      text: c.label,
                    ))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: _collections
              .map((c) => _ServiceListTab(category: c))
              .toList(),
        ),
      ),
    );
  }
}

class _ServiceListTab extends StatelessWidget {
  final _ServiceCategory category;

  const _ServiceListTab({required this.category});

  Stream<Map<String, dynamic>?> get _profileStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _profileStream,
      builder: (context, profileSnap) {
        final bp =
            (profileSnap.data?['businessProfile'] as Map<String, dynamic>?) ??
                {};
        final hiddenCategories =
            List<String>.from(bp['hiddenCategories'] ?? []);
        final isHidden = hiddenCategories.contains(category.collection);

        return Column(
          children: [
            // Switch ẩn/hiện danh mục
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hiển thị danh mục này',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !isHidden
                              ? 'Khách hàng có thể thấy và đặt dịch vụ'
                              : 'Đã tắt. Khách hàng không thể thấy danh mục này',
                          style: TextStyle(
                            fontSize: 12,
                            color: !isHidden
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !isHidden,
                    activeColor: const Color(0xFF6B5FB5),
                    onChanged: (val) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text(val ? 'Hiển thị danh mục?' : 'Tắt danh mục?'),
                          content: Text(
                            val 
                              ? 'Khách hàng sẽ có thể thấy và đặt các dịch vụ trong danh mục này.'
                              : 'Khách hàng sẽ không thể thấy danh mục này. Bạn có chắc chắn không?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: val ? Colors.green : Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(val ? 'Hiển thị' : 'Tắt'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      final svc = FirebaseAccountService();
                      final profile = await svc.getExtendedProfile() ?? {};
                      final bProfile = Map<String, dynamic>.from(
                        (profile['businessProfile'] as Map<String, dynamic>?) ??
                            {},
                      );
                      final hiddenList =
                          List<String>.from(bProfile['hiddenCategories'] ?? []);
                      if (val) {
                        hiddenList.remove(category.collection);
                      } else {
                        if (!hiddenList.contains(category.collection)) {
                          hiddenList.add(category.collection);
                        }
                      }
                      bProfile['hiddenCategories'] = hiddenList;
                      await svc.updateExtendedProfile(
                        {'businessProfile': bProfile},
                      );
                      
                      // Cập nhật tất cả dịch vụ trong danh mục
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        final batch = FirebaseFirestore.instance.batch();
                        final snap = await FirebaseFirestore.instance
                            .collection(category.collection)
                            .where('ownerId', isEqualTo: uid)
                            .get();
                        for (var doc in snap.docs) {
                          batch.update(doc.reference, {'categoryHidden': !val});
                        }
                        await batch.commit();
                      }
                    },
                  ),
                ],
              ),
            ),
            // Danh sách dịch vụ
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseBusinessService().streamMyServices(
                  collectionName: category.collection,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Lỗi tải dữ liệu:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category.icon,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có dịch vụ nào',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tạo dịch vụ từ trang chủ doanh nghiệp',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ServiceCard(service: items[index], category: category, isCategoryHidden: isHidden),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final _ServiceCategory category;
  final bool isCategoryHidden;

  const _ServiceCard({
    required this.service, 
    required this.category,
    this.isCategoryHidden = false,
  });

  String _formatCurrency(dynamic value) {
    if (value == null) return '-';
    final number =
        value is num ? value.toInt() : int.tryParse(value.toString());
    if (number == null) return '-';
    final s = number.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  Future<void> _confirmToggleStatus(BuildContext context, bool isActive) async {
    final actionName = isActive ? 'Ngừng hoạt động' : 'Kích hoạt lại';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionName dịch vụ?'),
        content: Text(
          isActive 
            ? 'Khách hàng sẽ không thể thấy và đặt dịch vụ "${service['name'] ?? ''}". Bạn có chắc chắn không?'
            : 'Dịch vụ "${service['name'] ?? ''}" sẽ hiển thị lại cho khách hàng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isActive ? 'Ngừng' : 'Bật lại'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    
    final result = await FirebaseBusinessService().updateService(
      collectionName: category.collection,
      docId: service['id'] as String,
      data: {'status': isActive ? 'inactive' : 'active'},
    );
    
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'Đã cập nhật trạng thái' : 'Lỗi: ${result.error}'),
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa dịch vụ?'),
        content: Text(
          'Dịch vụ "${service['name'] ?? ''}" sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await FirebaseBusinessService().deleteService(
      collectionName: category.collection,
      docId: service['id'] as String,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'Đã xóa dịch vụ' : 'Lỗi: ${result.error}'),
        backgroundColor: result.success ? null : Colors.red,
      ),
    );
  }

  void _openEdit(BuildContext context) {
    final data = service;
    final docId = data['id'] as String;
    Widget? page;
    switch (category.collection) {
      case 'business_transport_services':
        page = CreateTransportServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_flight_ticket_services':
        page = CreateFlightTicketServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_ship_ticket_services':
        page = CreateShipTicketServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_train_ticket_services':
        page = CreateTrainTicketServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_bus_ticket_services':
        page = CreateBusTicketServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_hotel_services':
        page = CreateHotelServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_guide_services':
        page = CreateGuideServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_photographer_services':
        page = CreatePhotographerServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_clothes_services':
        page = CreateClothesServicePage(initialData: data, existingDocId: docId);
        break;
      case 'business_food_services':
        page = CreateFoodServicePage(initialData: data, existingDocId: docId);
        break;
    }
    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
    final imageUrl = (extra['imageUrl'] ?? '').toString();
    final name = (service['name'] ?? 'Không có tên').toString();
    final price = _formatCurrency(service['price']);
    final description = (service['description'] ?? '').toString();
    final status = (service['status'] ?? 'active').toString();
    final createdAt = service['createdAt'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      dateStr = '${d.day}/${d.month}/${d.year}';
    }

    final isActive = status == 'active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0x1F6B5FB5)),
      ),
      child: Row(
        children: [
          // Ảnh dịch vụ
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: SizedBox(
              width: 100,
              height: 100,
              child: imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFF1F1F1),
                      alignment: Alignment.center,
                      child: Icon(category.icon, color: Colors.grey, size: 28),
                    )
                  : Image(
                      image: getImageProvider(imageUrl) ?? const AssetImage(''),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF1F1F1),
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          // Thông tin
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên + badge trạng thái
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCategoryHidden 
                              ? Colors.grey.shade200
                              : (isActive ? const Color(0xFFDCF6E6) : const Color(0xFFFCE4E4)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isCategoryHidden 
                              ? 'Ẩn theo danh mục'
                              : (isActive ? 'Đang hoạt động' : 'Đã ngừng'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isCategoryHidden 
                                ? Colors.grey.shade700
                                : (isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Giá
                  Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF6B5FB5),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tạo ngày $dateStr',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Các nút thao tác
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  activeColor: const Color(0xFF6B5FB5),
                  onChanged: (val) => _confirmToggleStatus(context, isActive),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF6B5FB5), size: 20),
                onPressed: () => _openEdit(context),
                tooltip: 'Sửa dịch vụ',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context),
                tooltip: 'Xóa dịch vụ',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ServiceCategory {
  final String label;
  final String collection;
  final IconData icon;

  const _ServiceCategory(this.label, this.collection, this.icon);
}
