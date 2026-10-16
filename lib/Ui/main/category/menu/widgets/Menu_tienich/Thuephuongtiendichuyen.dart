import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/thuephuongtiendichuye/cacphuongtienkhac.dart';
import 'package:tourn/Ui/main/category/business/business_onboarding_helper.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/thuephuongtiendichuye/xedap.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/thuephuongtiendichuye/xemay.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/thuephuongtiendichuye/xeoto.dart';
import 'menu_item.dart';

class Thuephuongtiendichuyen extends StatelessWidget {
  const Thuephuongtiendichuyen({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      collectionName: 'business_transport_services',
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ThuephuongtiendichuyenPage(),
              ),
            );
          },
      icon: const Icon(
        Icons.commute_outlined,
        size: 36,
        color: Colors.deepPurple,
      ),
      label: 'Thuê phương tiện di chuyển',
    );
  }
}

class ThuephuongtiendichuyenPage extends StatefulWidget {
  const ThuephuongtiendichuyenPage({super.key});

  @override
  State<ThuephuongtiendichuyenPage> createState() =>
      _ThuephuongtiendichuyenPageState();
}

class _ThuephuongtiendichuyenPageState
    extends State<ThuephuongtiendichuyenPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BusinessOnboardingHelper.ensureBusinessSetup(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transports = [
      {
        'icon': Icons.directions_car,
        'title': 'Xe ô tô',
        'subtitle': 'Thuê xe cá nhân',
      },
      {
        'icon': Icons.motorcycle,
        'title': 'Xe máy',
        'subtitle': 'Linh hoạt, nhanh',
      },
      {
        'icon': Icons.pedal_bike,
        'title': 'Xe đạp',
        'subtitle': 'Thân thiện môi trường',
      },
      {
        'icon': Icons.more_horiz,
        'title': 'Các phương tiện khác',
        'subtitle': 'Tùy chọn khác',
      },
    ];

    const Color pageBg = Color(0xFFF6F2FA);
    const Color accent = Color(0xFF6B5FB5);
    const Color cardBg = Color(0xFFF8F5FF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phương tiện di chuyển'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DonHangCuaBanPage(serviceType: 'vehicle_rental'),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: pageBg,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                  child: const Icon(Icons.route, color: accent, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Chọn phương tiện phù hợp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '4 lựa chọn phổ biến cho hành trình của bạn',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(
              children: const [
                _InfoChip(label: 'Linh hoạt'),
                SizedBox(width: 8),
                _InfoChip(label: 'Đặt nhanh'),
                SizedBox(width: 8),
                _InfoChip(label: 'Tiện lợi'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
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
                    final title = t['title'] as String;
                    Widget dest;
                    switch (title) {
                      case 'Xe ô tô':
                        dest = const Xeoto();
                        break;
                      case 'Xe máy':
                        dest = const Xemay();
                        break;
                      case 'Xe đạp':
                        dest = const Xedap();
                        break;
                      case 'Các phương tiện khác':
                        dest = const Cacphuongtienkhac();
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
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0x1F6B5FB5)),
                    ),
                    elevation: 1.5,
                    shadowColor: const Color(0x1F000000),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  t['icon'] as IconData,
                                  size: 22,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                  fontSize: 12.5,
                                  color: Colors.grey[700],
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
                                foregroundColor: accent,
                              ),
                              onPressed: () {
                                final title = t['title'] as String;
                                Widget dest;
                                switch (title) {
                                  case 'Xe ô tô':
                                    dest = const Xeoto();
                                    break;
                                  case 'Xe máy':
                                    dest = const Xemay();
                                    break;
                                  case 'Xe đạp':
                                    dest = const Xedap();
                                    break;
                                  case 'Các phương tiện khác':
                                    dest = const Cacphuongtienkhac();
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1F6B5FB5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B5FB5),
        ),
      ),
    );
  }
}
