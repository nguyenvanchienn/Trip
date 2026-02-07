import 'package:flutter/material.dart';
import 'menu_item.dart';

// Detail pages for transport types
import 'widgets/Phuongtiendichuyen/xebus.dart';
import 'widgets/Phuongtiendichuyen/lichsu.dart';
import 'widgets/Phuongtiendichuyen/xekhach.dart';
import 'widgets/Phuongtiendichuyen/Taxi.dart';
import 'widgets/Phuongtiendichuyen/Oto.dart';
import 'widgets/Phuongtiendichuyen/Tauhoa.dart';
import 'widgets/Phuongtiendichuyen/Maybay.dart';
import 'widgets/Phuongtiendichuyen/Xedap.dart';
import 'widgets/Phuongtiendichuyen/Xemay.dart';

class PhuongTienDiChuyen extends StatelessWidget {
  const PhuongTienDiChuyen({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Phuongtiendichuyen()),
            );
          },
      icon: const Icon(
        Icons.commute_outlined,
        size: 36,
        color: Colors.deepPurple,
      ),
      label: 'Phương tiện di chuyển',
    );
  }
}

class Phuongtiendichuyen extends StatelessWidget {
  const Phuongtiendichuyen({super.key});

  @override
  Widget build(BuildContext context) {
    final transports = [
      {
        'icon': Icons.directions_bus,
        'title': 'Xe buýt',
        'subtitle': 'Tiết kiệm, nhiều tuyến',
      },
      {
        'icon': Icons.directions_bus_outlined,
        'title': 'Xe khách',
        'subtitle': 'Thân thiện, thoải mái',
      },
      {
        'icon': Icons.local_taxi,
        'title': 'Taxi',
        'subtitle': 'Nhanh, tiện lợi',
      },
      {
        'icon': Icons.directions_car,
        'title': 'Ô tô',
        'subtitle': 'Thuê xe cá nhân',
      },
      {'icon': Icons.train, 'title': 'Tàu hỏa', 'subtitle': 'Đi xa, an toàn'},
      {
        'icon': Icons.flight,
        'title': 'Máy bay',
        'subtitle': 'Nhanh cho chặng dài',
      },
      {
        'icon': Icons.pedal_bike,
        'title': 'Xe đạp',
        'subtitle': 'Thân thiện môi trường',
      },
      {
        'icon': Icons.motorcycle,
        'title': 'Xe máy',
        'subtitle': 'Linh hoạt, nhanh',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phương tiện di chuyển'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
                );
              },
              icon: const Icon(Icons.history_outlined),
              label: const Text('Lịch sử đặt vé'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: transports.length,
              itemBuilder: (context, index) {
                final t = transports[index];
                return GestureDetector(
                  onTap: () {
                    final title =
                        t['title'] as String; //Lấy tiêu đề phương tiện
                    Widget dest; //dùng để lưu trang đích
                    switch (title) {
                      case 'Xe buýt':
                        dest = const XebusPage();
                        break;
                      case 'Xe khách':
                        dest = const XekhachPage();
                        break;
                      case 'Taxi':
                        dest = const TaxiPage();
                        break;
                      case 'Ô tô':
                        dest = const OtoPage();
                        break;
                      case 'Tàu hỏa':
                        dest = const TauhoaPage();
                        break;
                      case 'Máy bay':
                        dest = const MaybayPage();
                        break;
                      case 'Xe đạp':
                        dest = const XedapPage();
                        break;
                      case 'Xe máy':
                        dest = const XemayPage();
                        break;
                      default:
                        dest = Scaffold(
                          appBar: AppBar(title: Text(title)),
                          body: const Center(child: Text('Chi tiết')),
                        );
                    }
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => dest));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(t['icon'] as IconData, size: 26),
                              const SizedBox(height: 6),
                              Text(
                                t['title'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                final title = t['title'] as String;
                                Widget dest;
                                switch (title) {
                                  case 'Xe buýt':
                                    dest = const XebusPage();
                                    break;
                                  case 'Xe khách':
                                    dest = const XekhachPage();
                                    break;
                                  case 'Taxi':
                                    dest = const TaxiPage();
                                    break;
                                  case 'Ô tô':
                                    dest = const OtoPage();
                                    break;
                                  case 'Tàu hỏa':
                                    dest = const TauhoaPage();
                                    break;
                                  case 'Máy bay':
                                    dest = const MaybayPage();
                                    break;
                                  case 'Xe đạp':
                                    dest = const XedapPage();
                                    break;
                                  case 'Xe máy':
                                    dest = const XemayPage();
                                    break;
                                  default:
                                    dest = Scaffold(
                                      appBar: AppBar(title: Text(title)),
                                      body: const Center(
                                        child: Text('Chi tiết'),
                                      ),
                                    );
                                }
                                Navigator.of(
                                  context,
                                ).push(MaterialPageRoute(builder: (_) => dest));
                              },
                              child: const Text('Chi tiết'),
                            ),
                          ),
                        ],
                      ),
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
