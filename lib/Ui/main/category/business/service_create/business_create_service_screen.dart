import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_transport_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_flight_ticket_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_ship_ticket_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_train_ticket_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_bus_ticket_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_hotel_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_guide_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_photographer_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_clothes_service_page.dart';
import 'package:tourn/Ui/main/category/business/service_create/create_food_service_page.dart';

class BusinessCreateServiceScreen extends StatelessWidget {
  const BusinessCreateServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ServiceCreateItem>[
      _ServiceCreateItem(
        title: 'Thuê phương tiện di chuyển',
        subtitle: 'Xe ô tô, xe máy, xe đạp, khác',
        icon: Icons.commute_outlined,
        page: const CreateTransportServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Đặt vé máy bay',
        subtitle: 'Tạo dịch vụ vé máy bay',
        icon: Icons.flight_takeoff,
        page: const CreateFlightTicketServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Đặt vé tàu',
        subtitle: 'Tàu/phà',
        icon: Icons.directions_boat,
        page: const CreateShipTicketServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Đặt vé tàu hỏa',
        subtitle: 'Tàu lửa, đường sắt',
        icon: Icons.train,
        page: const CreateTrainTicketServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Đặt vé xe khách',
        subtitle: 'Limousine, giường nằm',
        icon: Icons.directions_bus,
        page: const CreateBusTicketServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Đặt phòng khách sạn',
        subtitle: 'Phòng, resort, homestay',
        icon: Icons.home_work_outlined,
        page: const CreateHotelServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Thuê hướng dẫn viên',
        subtitle: 'Hướng dẫn, tour địa phương',
        icon: Icons.support_agent_outlined,
        page: const CreateGuideServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Thuê thợ chụp ảnh',
        subtitle: 'Chụp ngoại cảnh, kỷ niệm',
        icon: Icons.photo_camera_outlined,
        page: const CreatePhotographerServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Thuê quần áo & phụ kiện',
        subtitle: 'Áo dài, vest, trang phục',
        icon: Icons.checkroom_outlined,
        page: const CreateClothesServicePage(),
      ),
      _ServiceCreateItem(
        title: 'Ẩm thực vùng miền',
        subtitle: 'Đặc sản, món ngon địa phương',
        icon: Icons.restaurant_menu,
        page: const CreateFoodServicePage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo dịch vụ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ServiceCreateCard(item: item),
            ),
        ],
      ),
    );
  }
}

class _ServiceCreateCard extends StatelessWidget {
  const _ServiceCreateCard({required this.item});

  final _ServiceCreateItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => item.page));
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1F6B5FB5)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF1ECFF),
            child: Icon(item.icon, color: const Color(0xFF6B5FB5)),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(item.subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _ServiceCreateItem {
  const _ServiceCreateItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
}
